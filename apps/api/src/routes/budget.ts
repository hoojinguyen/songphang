import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import { BudgetResponse, PutBudgetRequest } from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { requireGroupRole } from "../auth/group-access.js";
import { requireSameOrigin, requireUser } from "../auth/middleware.js";
import {
	requireVerifiedEmail,
	requireWriteLimit,
} from "../auth/verified-email.js";
import { getBudget, putBudget, removeBudget } from "../services/budget.js";

const params = z.object({ groupId: z.uuid() });
const path = "/api/v1/groups/{groupId}/budget";

export function registerBudgetRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	const read = [requireUser(deps), requireGroupRole(deps, "viewer")];
	const writeOwner = [
		requireUser(deps),
		requireGroupRole(deps, "owner"),
		requireVerifiedEmail(deps),
		requireWriteLimit(deps),
		requireSameOrigin(deps.config),
	];
	app.openapi(
		createRoute({
			method: "get",
			path,
			middleware: read,
			request: { params },
			responses: {
				200: {
					description: "Group budget",
					content: { "application/json": { schema: BudgetResponse } },
				},
			},
		}),
		async (context) =>
			context.json(await getBudget(deps, context.var.groupAccess.groupId), 200),
	);
	app.openapi(
		createRoute({
			method: "put",
			path,
			middleware: writeOwner,
			request: {
				params,
				body: {
					required: true,
					content: { "application/json": { schema: PutBudgetRequest } },
				},
			},
			responses: {
				200: {
					description: "Group budget saved",
					content: { "application/json": { schema: BudgetResponse } },
				},
			},
		}),
		async (context) =>
			context.json(
				await putBudget(deps, {
					groupId: context.var.groupAccess.groupId,
					userId: context.var.user.id,
					request: context.req.valid("json"),
				}),
				200,
			),
	);
	app.openapi(
		createRoute({
			method: "delete",
			path,
			middleware: writeOwner,
			request: { params },
			responses: { 204: { description: "Group budget removed" } },
		}),
		async (context) => {
			await removeBudget(deps, {
				groupId: context.var.groupAccess.groupId,
				userId: context.var.user.id,
			});
			return context.body(null, 204);
		},
	);
}
