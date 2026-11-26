import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	SettlementVaultQuery,
	SettlementVaultResponse,
} from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { requireGroupRole } from "../auth/group-access.js";
import { requireUser } from "../auth/middleware.js";
import { getSettlementVault } from "../services/settlement-vault.js";

const route = createRoute({
	method: "get",
	path: "/api/v1/groups/{groupId}/settlement-vault",
	request: {
		params: z.object({ groupId: z.uuid() }),
		query: SettlementVaultQuery,
	},
	responses: {
		200: {
			description: "Unified settlement history and proof vault",
			content: { "application/json": { schema: SettlementVaultResponse } },
		},
	},
});

export function registerSettlementVaultRoutes(
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
				await getSettlementVault(
					deps,
					context.var.groupAccess.groupId,
					context.req.valid("query"),
				),
				200,
			),
	);
}
