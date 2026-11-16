import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import { ActivityQuery, ActivityResponse } from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { requireGroupRole } from "../auth/group-access.js";
import { requireUser } from "../auth/middleware.js";
import { listActivity } from "../services/activity.js";
export function registerActivityRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
) {
	app.openapi(
		createRoute({
			method: "get",
			path: "/api/v1/groups/{groupId}/activity",
			middleware: [requireUser(deps), requireGroupRole(deps, "viewer")],
			request: {
				params: z.object({ groupId: z.uuid() }),
				query: ActivityQuery,
			},
			responses: {
				200: {
					description: "Activity",
					content: { "application/json": { schema: ActivityResponse } },
				},
			},
		}),
		async (c) =>
			c.json(
				await listActivity(
					deps,
					c.var.groupAccess.groupId,
					c.req.valid("query"),
				),
				200,
			),
	);
}
