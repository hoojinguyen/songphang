import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	ConfirmSettlementResponse,
	CreateSettlementRequest,
	IdempotencyKeyHeader,
	SettlementRequestResponse,
	SettlementRequestsQuery,
	SettlementRequestsResponse,
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
	createSettlementRequest,
	getSettlementRequests,
	resolveSettlement,
} from "../services/settlement-requests.js";

const params = z.object({ groupId: z.uuid() });
const path = "/api/v1/groups/{groupId}/settlement-requests";
export function registerSettlementRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
) {
	const read = [requireUser(deps), requireGroupRole(deps, "viewer")];
	const write = [
		...read,
		requireVerifiedEmail(deps),
		requireWriteLimit(deps),
		requireSameOrigin(deps.config),
	];
	app.openapi(
		createRoute({
			method: "get",
			path,
			middleware: read,
			request: { params, query: SettlementRequestsQuery },
			responses: {
				200: {
					description: "Settlement requests",
					content: {
						"application/json": { schema: SettlementRequestsResponse },
					},
				},
			},
		}),
		async (context) =>
			context.json(
				await getSettlementRequests(
					deps,
					context.var.groupAccess.groupId,
					context.req.valid("query"),
				),
				200,
			),
	);
	app.openapi(
		createRoute({
			method: "post",
			path,
			middleware: write,
			request: {
				params,
				headers: z.object({ "idempotency-key": IdempotencyKeyHeader }),
				body: {
					required: true,
					content: { "application/json": { schema: CreateSettlementRequest } },
				},
			},
			responses: {
				201: {
					description: "Payment reported",
					content: {
						"application/json": { schema: SettlementRequestResponse },
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
					requestHash: hashRequest("POST", context.req.path, request),
					onCommitted: () =>
						deps.events.publishChanged(context.var.groupAccess.groupId, [
							"settlementRequests",
						]),
				},
				async (executor) => ({
					status: 201,
					body: await createSettlementRequest(executor, {
						groupId: context.var.groupAccess.groupId,
						userId: context.var.user.id,
						request,
						now: deps.now(),
					}),
				}),
			);
			return context.json(SettlementRequestResponse.parse(response.body), 201);
		},
	);
	for (const action of ["confirm", "reject", "cancel"] as const) {
		const responseSchema =
			action === "confirm"
				? ConfirmSettlementResponse
				: SettlementRequestResponse;
		app.openapi(
			createRoute({
				method: "post",
				path: `${path}/{id}/${action}`,
				middleware: write,
				request: { params: params.extend({ id: z.uuid() }) },
				responses: {
					200: {
						description: "Payment report resolved",
						content: { "application/json": { schema: responseSchema } },
					},
				},
			}),
			async (context) =>
				context.json(
					responseSchema.parse(
						await resolveSettlement(deps, {
							groupId: context.var.groupAccess.groupId,
							userId: context.var.user.id,
							id: context.req.valid("param").id,
							action,
						}),
					),
					200,
				),
		);
	}
}
