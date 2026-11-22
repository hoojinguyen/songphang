import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	DeleteAccountRequest,
	ErrorResponse,
	MeResponse,
	PushSettingsResponse,
	RegisterDeviceRequest,
	RegisterDeviceResponse,
	SessionsResponse,
	UpdatePushSettingsRequest,
} from "@songphang/contract";
import { deleteCookie } from "hono/cookie";
import type { AppDeps, AppEnv } from "../app.js";
import { requireSameOrigin, requireUser } from "../auth/middleware.js";
import { SESSION_COOKIE, sessionCookieAttributes } from "../auth/sessions.js";
import { AppError } from "../errors.js";
import { listActiveSessions, revokeUserSession } from "../services/accounts.js";
import {
	registerPushDevice,
	removePushDevice,
	updatePushSettings,
} from "../services/devices.js";
import { deleteAccount } from "../services/password-recovery.js";

export function registerMeRoute(app: OpenAPIHono<AppEnv>, deps: AppDeps): void {
	app.openapi(
		createRoute({
			method: "delete",
			path: "/api/v1/me",
			middleware: [requireUser(deps), requireSameOrigin(deps.config)],
			request: {
				body: {
					required: true,
					content: { "application/json": { schema: DeleteAccountRequest } },
				},
			},
			responses: {
				204: { description: "Account deleted" },
				503: {
					description: "Apple revocation failed",
					content: { "application/json": { schema: ErrorResponse } },
				},
			},
		}),
		async (context) => {
			await deleteAccount(deps, {
				user: context.var.user,
				request: context.req.valid("json"),
			});
			if (context.var.sessionTransport !== "bearer") {
				deleteCookie(
					context,
					SESSION_COOKIE,
					sessionCookieAttributes(deps.config.appEnv),
				);
			}
			return context.body(null, 204);
		},
	);
	app.openapi(
		createRoute({
			method: "get",
			path: "/api/v1/me",
			middleware: [requireUser(deps)],
			responses: {
				200: {
					description: "Current user",
					content: { "application/json": { schema: MeResponse } },
				},
				401: {
					description: "Authentication required",
					content: { "application/json": { schema: ErrorResponse } },
				},
			},
		}),
		(context) =>
			context.json(MeResponse.parse({ user: context.get("user") }), 200),
	);
	app.openapi(
		createRoute({
			method: "get",
			path: "/api/v1/me/sessions",
			middleware: [requireUser(deps)],
			responses: {
				200: {
					description: "Active sessions for the current user",
					content: { "application/json": { schema: SessionsResponse } },
				},
				401: {
					description: "Authentication required",
					content: { "application/json": { schema: ErrorResponse } },
				},
			},
		}),
		async (context) =>
			context.json(
				SessionsResponse.parse(
					await listActiveSessions(deps, {
						userId: context.var.user.id,
						currentToken: context.var.sessionToken,
					}),
				),
				200,
			),
	);
	app.openapi(
		createRoute({
			method: "delete",
			path: "/api/v1/me/sessions/{id}",
			middleware: [requireUser(deps), requireSameOrigin(deps.config)],
			request: {
				params: z.object({ id: z.uuid() }),
			},
			responses: {
				204: { description: "Session revoked" },
				401: {
					description: "Authentication required",
					content: { "application/json": { schema: ErrorResponse } },
				},
				404: {
					description: "Session not found",
					content: { "application/json": { schema: ErrorResponse } },
				},
			},
		}),
		async (context) => {
			const { isCurrent } = await revokeUserSession(deps, {
				userId: context.var.user.id,
				sessionId: context.req.valid("param").id,
				currentToken: context.var.sessionToken,
			});
			if (isCurrent && context.var.sessionTransport !== "bearer") {
				deleteCookie(
					context,
					SESSION_COOKIE,
					sessionCookieAttributes(deps.config.appEnv),
				);
			}
			return context.body(null, 204);
		},
	);
	if (deps.config.pushProvider) {
		app.openapi(
			createRoute({
				method: "post",
				path: "/api/v1/me/devices",
				middleware: [requireUser(deps), requireSameOrigin(deps.config)],
				request: {
					body: {
						required: true,
						content: {
							"application/json": { schema: RegisterDeviceRequest },
						},
					},
				},
				responses: {
					200: {
						description: "Push device registered",
						content: {
							"application/json": { schema: RegisterDeviceResponse },
						},
					},
					401: {
						description: "Authentication required",
						content: { "application/json": { schema: ErrorResponse } },
					},
					403: {
						description: "Native session required",
						content: { "application/json": { schema: ErrorResponse } },
					},
					422: {
						description: "Device registration limit reached",
						content: { "application/json": { schema: ErrorResponse } },
					},
				},
			}),
			async (context) => {
				if (
					context.var.sessionTransport !== "bearer" ||
					context.var.sessionClient === "web"
				) {
					throw new AppError(
						403,
						"FORBIDDEN",
						"Push device registration requires a native Bearer session",
					);
				}
				const result = await registerPushDevice(deps, {
					userId: context.var.user.id,
					sessionId: context.var.sessionId,
					request: context.req.valid("json"),
				});
				context.header("Cache-Control", "no-store");
				return context.json(RegisterDeviceResponse.parse(result), 200);
			},
		);
		app.openapi(
			createRoute({
				method: "delete",
				path: "/api/v1/me/devices/{id}",
				middleware: [requireUser(deps), requireSameOrigin(deps.config)],
				request: {
					params: z.object({ id: z.uuid() }),
				},
				responses: {
					204: { description: "Push device removed" },
					401: {
						description: "Authentication required",
						content: { "application/json": { schema: ErrorResponse } },
					},
					404: {
						description: "Push device not found",
						content: { "application/json": { schema: ErrorResponse } },
					},
				},
			}),
			async (context) => {
				await removePushDevice(deps, {
					userId: context.var.user.id,
					id: context.req.valid("param").id,
				});
				return context.body(null, 204);
			},
		);
		app.openapi(
			createRoute({
				method: "put",
				path: "/api/v1/me/push-settings",
				middleware: [requireUser(deps), requireSameOrigin(deps.config)],
				request: {
					body: {
						required: true,
						content: {
							"application/json": { schema: UpdatePushSettingsRequest },
						},
					},
				},
				responses: {
					200: {
						description: "Push settings updated",
						content: {
							"application/json": { schema: PushSettingsResponse },
						},
					},
					401: {
						description: "Authentication required",
						content: { "application/json": { schema: ErrorResponse } },
					},
					404: {
						description: "User not found",
						content: { "application/json": { schema: ErrorResponse } },
					},
				},
			}),
			async (context) => {
				const result = await updatePushSettings(deps, {
					userId: context.var.user.id,
					hideContent: context.req.valid("json").hideContent,
				});
				return context.json(PushSettingsResponse.parse(result), 200);
			},
		);
	}
}
