import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	DeleteAccountRequest,
	ErrorResponse,
	MeResponse,
	SessionsResponse,
} from "@songphang/contract";
import { deleteCookie } from "hono/cookie";
import type { AppDeps, AppEnv } from "../app.js";
import { requireSameOrigin, requireUser } from "../auth/middleware.js";
import { SESSION_COOKIE, sessionCookieAttributes } from "../auth/sessions.js";
import { listActiveSessions, revokeUserSession } from "../services/accounts.js";
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
			responses: { 204: { description: "Account deleted" } },
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
}
