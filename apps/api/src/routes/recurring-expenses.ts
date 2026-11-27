import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	CreateRecurringExpenseRequest,
	IdempotencyKeyHeader,
	RecurringExpenseResponse,
	RecurringExpensesResponse,
	UpdateRecurringExpenseRequest,
} from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { requireGroupRole } from "../auth/group-access.js";
import { requireSameOrigin, requireUser } from "../auth/middleware.js";
import {
	requireVerifiedEmail,
	requireWriteLimit,
} from "../auth/verified-email.js";
import { hashRequest, runIdempotent } from "../idempotency.js";
import {
	createRecurringExpense,
	editRecurringExpense,
	listRecurringExpenses,
	removeRecurringExpense,
	skipRecurringExpense,
} from "../services/recurring-expenses.js";

const params = z.object({ groupId: z.uuid() });
const recurringParams = params.extend({ recurringId: z.string().max(100) });

export function registerRecurringExpenseRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	const read = [requireUser(deps), requireGroupRole(deps, "viewer")];
	const write = [
		requireUser(deps),
		requireGroupRole(deps, "editor"),
		requireVerifiedEmail(deps),
		requireWriteLimit(deps),
		requireSameOrigin(deps.config),
	];

	app.openapi(
		createRoute({
			method: "get",
			path: "/api/v1/groups/{groupId}/recurring-expenses",
			middleware: read,
			request: { params },
			responses: {
				200: {
					description: "Group recurring expenses",
					content: {
						"application/json": { schema: RecurringExpensesResponse },
					},
				},
			},
		}),
		async (context) =>
			context.json(
				await listRecurringExpenses(deps, context.var.groupAccess.groupId),
				200,
			),
	);

	app.openapi(
		createRoute({
			method: "post",
			path: "/api/v1/groups/{groupId}/recurring-expenses",
			middleware: write,
			request: {
				params,
				headers: z.object({ "idempotency-key": IdempotencyKeyHeader }),
				body: {
					required: true,
					content: {
						"application/json": { schema: CreateRecurringExpenseRequest },
					},
				},
			},
			responses: {
				201: {
					description: "Recurring expense created",
					content: {
						"application/json": { schema: RecurringExpenseResponse },
					},
				},
			},
		}),
		async (context) => {
			const request = context.req.valid("json");
			const response = await runIdempotent(
				deps,
				{
					userId: context.var.user.id,
					key: context.req.valid("header")["idempotency-key"],
					onCommitted: () =>
						deps.events.publishChanged(context.var.groupAccess.groupId, [
							"activity",
							"recurringExpenses",
						]),
					requestHash: hashRequest("POST", context.req.path, request),
				},
				async (executor) => ({
					status: 201,
					body: await createRecurringExpense(executor, {
						groupId: context.var.groupAccess.groupId,
						userId: context.var.user.id,
						request,
						now: deps.now(),
					}),
				}),
			);
			return context.json(RecurringExpenseResponse.parse(response.body), 201);
		},
	);

	app.openapi(
		createRoute({
			method: "patch",
			path: "/api/v1/groups/{groupId}/recurring-expenses/{recurringId}",
			middleware: write,
			request: {
				params: recurringParams,
				body: {
					required: true,
					content: {
						"application/json": { schema: UpdateRecurringExpenseRequest },
					},
				},
			},
			responses: {
				200: {
					description: "Recurring expense updated",
					content: {
						"application/json": { schema: RecurringExpenseResponse },
					},
				},
			},
		}),
		async (context) =>
			context.json(
				await editRecurringExpense(deps, {
					groupId: context.var.groupAccess.groupId,
					userId: context.var.user.id,
					recurringId: context.req.valid("param").recurringId,
					request: context.req.valid("json"),
				}),
				200,
			),
	);

	app.openapi(
		createRoute({
			method: "delete",
			path: "/api/v1/groups/{groupId}/recurring-expenses/{recurringId}",
			middleware: write,
			request: { params: recurringParams },
			responses: {
				204: { description: "Recurring expense deleted" },
			},
		}),
		async (context) => {
			await removeRecurringExpense(deps, {
				groupId: context.var.groupAccess.groupId,
				userId: context.var.user.id,
				recurringId: context.req.valid("param").recurringId,
			});
			return context.body(null, 204);
		},
	);

	app.openapi(
		createRoute({
			method: "post",
			path: "/api/v1/groups/{groupId}/recurring-expenses/{recurringId}/skip",
			middleware: write,
			request: { params: recurringParams },
			responses: {
				200: {
					description: "Recurring expense occurrence skipped",
					content: {
						"application/json": { schema: RecurringExpenseResponse },
					},
				},
			},
		}),
		async (context) =>
			context.json(
				await skipRecurringExpense(deps, {
					groupId: context.var.groupAccess.groupId,
					userId: context.var.user.id,
					recurringId: context.req.valid("param").recurringId,
				}),
				200,
			),
	);
}
