import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	CreateTransactionRequest,
	IdempotencyKeyHeader,
	ParseRequest,
	ParseResponse,
	PreviewItemsRequest,
	PreviewItemsResponse,
	PreviewTransactionRequest,
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
import { parseSentence } from "../services/quick-entry.js";
import {
	createTransaction,
	listTransactions,
	previewItemsSplit,
	previewTransaction,
} from "../services/transactions.js";
import { registerTransactionChangeRoutes } from "./transaction-changes.js";

const parseRoute = createRoute({
	method: "post",
	path: "/api/v1/groups/{groupId}/transactions/parse",
	request: {
		params: z.object({ groupId: z.uuid() }),
		body: {
			required: true,
			content: { "application/json": { schema: ParseRequest } },
		},
	},
	responses: {
		200: {
			description: "Sentence interpretation",
			content: { "application/json": { schema: ParseResponse } },
		},
	},
});
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
	request: {
		params,
		body: {
			required: true,
			content: { "application/json": { schema: PreviewTransactionRequest } },
		},
	},
	responses: {
		200: {
			description: "Shares preview",
			content: { "application/json": { schema: PreviewTransactionResponse } },
		},
	},
});
const previewItemsRoute = createRoute({
	method: "post",
	path: "/api/v1/groups/{groupId}/transactions/items/preview",
	request: {
		params,
		body: {
			required: true,
			content: { "application/json": { schema: PreviewItemsRequest } },
		},
	},
	responses: {
		200: {
			description: "Items split calculation",
			content: { "application/json": { schema: PreviewItemsResponse } },
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
	app.openapi(
		{
			...parseRoute,
			middleware: [
				requireUser(deps),
				requireGroupRole(deps, "editor"),
				requireVerifiedEmail(deps),
				requireSameOrigin(deps.config),
				deps.rateLimiter.limit({
					name: "parse",
					max: 120,
					windowMs: 60000,
					key: (context) => context.var.user.id,
				}),
			],
		},
		async (context) =>
			context.json(
				await parseSentence(deps, {
					groupId: context.var.groupAccess.groupId,
					userId: context.var.user.id,
					memberId: context.var.groupAccess.memberId,
					request: context.req.valid("json"),
				}),
				200,
			),
	);
	registerTransactionChangeRoutes(app, deps);
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
				context.var.user.id,
			),
			200,
		),
	);
	app.openapi({ ...previewRoute, middleware: write }, async (context) =>
		context.json(
			await previewTransaction(
				deps,
				context.var.groupAccess.groupId,
				context.var.user.id,
				context.req.valid("json"),
			),
			200,
		),
	);
	app.openapi({ ...previewItemsRoute, middleware: write }, async (context) =>
		context.json(
			await previewItemsSplit(
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
					onCommitted: () =>
						deps.events.publishChanged(context.var.groupAccess.groupId, [
							"transactions",
							"balances",
							"activity",
							"budget",
						]),
					requestHash: hashRequest("POST", context.req.path, request),
				},
				async (transaction) => ({
					status: 201,
					body: await createTransaction(transaction, {
						groupId: context.var.groupAccess.groupId,
						userId: context.var.user.id,
						request,
						now: deps.now(),
						enqueue: deps.enqueue,
						pushEnabled: Boolean(deps.config.pushProvider),
					}),
				}),
			);
			return context.json(TransactionResponse.parse(response.body), 201);
		},
	);
}
