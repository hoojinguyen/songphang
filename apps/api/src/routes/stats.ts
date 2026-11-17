import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import { StatsQuery, StatsResponse } from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { requireGroupRole } from "../auth/group-access.js";
import { requireUser } from "../auth/middleware.js";
import { getGroupStats } from "../services/stats.js";

export function registerStatsRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	app.openapi(
		createRoute({
			method: "get",
			path: "/api/v1/groups/{groupId}/stats",
			middleware: [requireUser(deps), requireGroupRole(deps, "viewer")],
			request: {
				params: z.object({ groupId: z.uuid() }),
				query: StatsQuery,
			},
			responses: {
				200: {
					description: "Group spending statistics",
					content: { "application/json": { schema: StatsResponse } },
				},
			},
		}),
		async (context) =>
			context.json(
				await getGroupStats(
					deps,
					context.var.groupAccess.groupId,
					context.req.valid("query"),
				),
				200,
			),
	);
}
