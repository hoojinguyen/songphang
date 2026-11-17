import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import type { AppDeps, AppEnv } from "../app.js";
import { requireGroupRole } from "../auth/group-access.js";
import { requireUser } from "../auth/middleware.js";
import { exportGroupCsv } from "../services/export.js";

export function registerExportRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	app.openapi(
		createRoute({
			method: "get",
			path: "/api/v1/groups/{groupId}/export.csv",
			middleware: [
				requireUser(deps),
				requireGroupRole(deps, "viewer"),
				deps.rateLimiter.limit({
					name: "exportCsv",
					max: 6,
					windowMs: 60000,
					key: (context) => context.var.user.id,
				}),
			],
			request: { params: z.object({ groupId: z.uuid() }) },
			responses: {
				200: {
					description: "Group transactions CSV",
					content: { "text/csv": { schema: z.string() } },
				},
			},
		}),
		async (context) => {
			const { filename, content } = await exportGroupCsv(
				deps,
				context.var.groupAccess.groupId,
			);
			return new Response(content, {
				status: 200,
				headers: {
					"Content-Type": "text/csv; charset=utf-8",
					"Content-Disposition": `attachment; filename="${filename}"`,
					"Cache-Control": "no-store",
				},
			});
		},
	);
}
