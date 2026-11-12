import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	CreateTransactionRequest,
	IdempotencyKeyHeader,
	PreviewTransactionResponse,
	TransactionResponse,
	TransactionsQuery,
	TransactionsResponse,
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
	createTransaction,
	listTransactions,
	previewTransaction,
} from "../services/transactions.js";

const params = z.object({ groupId: z.uuid() });
const body = {
	required: true,
	content: { "application/json": { schema: CreateTransactionRequest } },
};
const listRoute = createRoute({
	method: "get",
	path: "/api/v1/groups/{groupId}/transactions",
	request: { params, query: TransactionsQuery },
	responses: {
		200: {
			description: "Transactions",
			content: { "application/json": { schema: TransactionsResponse } },
		},
	},
});
const previewRoute = createRoute({
	method: "post",
	path: "/api/v1/groups/{groupId}/transactions/preview",
	request: { params, body },
	responses: {
		200: {
			description: "Shares preview",
			content: { "application/json": { schema: PreviewTransactionResponse } },
		},
	},
});
const createTransactionRoute = createRoute({
	method: "post",
	path: "/api/v1/groups/{groupId}/transactions",
	request: {
		params,
		headers: z.object({ "idempotency-key": IdempotencyKeyHeader }),
		body,
	},
	responses: {
		201: {
			description: "Transaction created",
			content: { "application/json": { schema: TransactionResponse } },
		},
	},
});
export function registerTransactionRoutes(
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
	app.openapi({ ...listRoute, middleware: read }, async (context) =>
		context.json(
			await listTransactions(
				deps,
				context.var.groupAccess.groupId,
				context.req.valid("query"),
			),
			200,
		),
	);
	app.openapi({ ...previewRoute, middleware: write }, async (context) =>
		context.json(
			await previewTransaction(
				deps,
				context.var.groupAccess.groupId,
				context.req.valid("json"),
			),
			200,
		),
	);
	app.openapi(
		{ ...createTransactionRoute, middleware: write },
		async (context) => {
			const request = context.req.valid("json");
			const response = await runIdempotent(
				deps,
				{
					userId: context.var.user.id,
					key: context.req.valid("header")["idempotency-key"],
					requestHash: hashRequest("POST", context.req.path, request),
				},
				async (transaction) => ({
					status: 201,
					body: await createTransaction(transaction, {
						groupId: context.var.groupAccess.groupId,
						userId: context.var.user.id,
						request,
						now: deps.now(),
					}),
				}),
			);
			return context.json(TransactionResponse.parse(response.body), 201);
		},
	);
}
