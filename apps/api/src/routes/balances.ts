import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import { BalancesResponse } from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { requireGroupRole } from "../auth/group-access.js";
import { requireUser } from "../auth/middleware.js";
import { getBalances } from "../services/balances.js";

const route = createRoute({
	method: "get",
	path: "/api/v1/groups/{groupId}/balances",
	request: { params: z.object({ groupId: z.uuid() }) },
	responses: {
		200: {
			description: "Balances and settlements",
			content: { "application/json": { schema: BalancesResponse } },
		},
	},
});
export function registerBalanceRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	app.openapi(
		{
			...route,
			middleware: [requireUser(deps), requireGroupRole(deps, "viewer")],
		},
		async (context) =>
			context.json(
				await getBalances(deps, context.var.groupAccess.groupId),
				200,
			),
	);
}
