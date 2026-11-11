import { createRoute, type OpenAPIHono } from "@hono/zod-openapi";
import { ErrorResponse, MeResponse } from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { requireUser } from "../auth/middleware.js";

export function registerMeRoute(app: OpenAPIHono<AppEnv>, deps: AppDeps): void {
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
