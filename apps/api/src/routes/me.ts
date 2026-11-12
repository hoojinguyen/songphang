import { createRoute, type OpenAPIHono } from "@hono/zod-openapi";
import {
	DeleteAccountRequest,
	ErrorResponse,
	MeResponse,
} from "@songphang/contract";
import { deleteCookie } from "hono/cookie";
import type { AppDeps, AppEnv } from "../app.js";
import { requireSameOrigin, requireUser } from "../auth/middleware.js";
import { SESSION_COOKIE, sessionCookieAttributes } from "../auth/sessions.js";
import { deleteAccount } from "../services/password-recovery.js";

export function registerMeRoute(app: OpenAPIHono<AppEnv>, deps: AppDeps): void {
	app.openapi(
		createRoute({
			method: "delete",
			path: "/api/v1/me",
			middleware: [requireSameOrigin(deps.config), requireUser(deps)],
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
			deleteCookie(
				context,
				SESSION_COOKIE,
				sessionCookieAttributes(deps.config.appEnv),
			);
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
}
