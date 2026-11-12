import { createRoute, type OpenAPIHono } from "@hono/zod-openapi";
import { ErrorResponse } from "@songphang/contract";
import { deleteCookie } from "hono/cookie";
import type { AppDeps, AppEnv } from "../app.js";
import { requireSameOrigin, requireUser } from "../auth/middleware.js";
import {
	deleteSession,
	SESSION_COOKIE,
	sessionCookieAttributes,
} from "../auth/sessions.js";
import { registerAccountAuthRoutes } from "./account-auth.js";

export function registerAuthRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	registerAccountAuthRoutes(app, deps);
	app.openapi(
		createRoute({
			method: "post",
			path: "/api/v1/auth/logout",
			middleware: [requireSameOrigin(deps.config), requireUser(deps)],
			responses: {
				204: { description: "Signed out" },
				400: {
					description: "Invalid origin",
					content: { "application/json": { schema: ErrorResponse } },
				},
				401: {
					description: "Authentication required",
					content: { "application/json": { schema: ErrorResponse } },
				},
			},
		}),
		async (context) => {
			await deleteSession(deps.db, context.get("sessionToken"));
			deleteCookie(
				context,
				SESSION_COOKIE,
				sessionCookieAttributes(deps.config.appEnv),
			);
			return context.body(null, 204);
		},
	);
}
