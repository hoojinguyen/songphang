import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	BalancesResponse,
	MemberBreakdownsQuery,
	MemberBreakdownsResponse,
} from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { requireGroupRole } from "../auth/group-access.js";
import { requireUser } from "../auth/middleware.js";
import { getBalances } from "../services/balances.js";
import { getMemberBreakdowns } from "../services/member-breakdowns.js";

const groupParams = z.object({ groupId: z.uuid() });

const route = createRoute({
	method: "get",
	path: "/api/v1/groups/{groupId}/balances",
	request: { params: groupParams },
	responses: {
		200: {
			description: "Balances and settlements",
			content: { "application/json": { schema: BalancesResponse } },
		},
	},
});

const breakdownsRoute = createRoute({
	method: "get",
	path: "/api/v1/groups/{groupId}/balances/breakdowns",
	request: { params: groupParams, query: MemberBreakdownsQuery },
	responses: {
		200: {
			description: "Server-computed per-member debt breakdowns",
			content: { "application/json": { schema: MemberBreakdownsResponse } },
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
				await getBalances(
					deps,
					context.var.groupAccess.groupId,
					context.var.user.id,
				),
				200,
			),
	);
	app.openapi(
		{
			...breakdownsRoute,
			middleware: [requireUser(deps), requireGroupRole(deps, "viewer")],
		},
		async (context) =>
			context.json(
				await getMemberBreakdowns(deps, {
					groupId: context.var.groupAccess.groupId,
					cycleId: context.req.valid("query").cycleId,
				}),
				200,
			),
	);
}
