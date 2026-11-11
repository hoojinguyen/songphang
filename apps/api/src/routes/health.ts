import { createRoute, type OpenAPIHono } from "@hono/zod-openapi";
import { HealthResponse } from "@songphang/contract";
import { checkDatabaseHealth, type Db } from "@songphang/db";
import type { AppEnv } from "../app.js";

const healthRoute = createRoute({
	method: "get",
	path: "/api/v1/health",
	responses: {
		200: {
			description: "The database is available",
			content: { "application/json": { schema: HealthResponse } },
		},
		503: {
			description: "The database is unavailable",
			content: { "application/json": { schema: HealthResponse } },
		},
	},
});

export function registerHealthRoute(app: OpenAPIHono<AppEnv>, db: Db): void {
	app.openapi(healthRoute, async (context) => {
		if (await checkDatabaseHealth(db)) {
			return context.json({ status: "ok", db: "ok" }, 200);
		}
		return context.json({ status: "degraded", db: "down" }, 503);
	});
}
