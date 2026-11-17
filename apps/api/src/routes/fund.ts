import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	CreateFundRequest,
	IdempotencyKeyHeader,
	MemberResponse,
	UpdateFundRequest,
} from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { requireGroupRole } from "../auth/group-access.js";
import { requireSameOrigin, requireUser } from "../auth/middleware.js";
import {
	requireVerifiedEmail,
	requireWriteLimit,
} from "../auth/verified-email.js";
import { hashRequest, runIdempotent } from "../idempotency.js";
import { createFund, deleteFund, updateFund } from "../services/fund.js";

const params = z.object({ groupId: z.uuid() });
const path = "/api/v1/groups/{groupId}/fund";

export function registerFundRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	const write = [
		requireUser(deps),
		requireGroupRole(deps, "editor"),
		requireVerifiedEmail(deps),
		requireWriteLimit(deps),
		requireSameOrigin(deps.config),
	];
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
					content: { "application/json": { schema: CreateFundRequest } },
				},
			},
			responses: {
				201: {
					description: "Fund created",
					content: { "application/json": { schema: MemberResponse } },
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
							"members",
							"balances",
							"activity",
						]),
				},
				async (executor) => ({
					status: 201,
					body: await createFund(executor, {
						groupId: context.var.groupAccess.groupId,
						userId: context.var.user.id,
						request,
						now: deps.now(),
					}),
				}),
			);
			return context.json(MemberResponse.parse(response.body), 201);
		},
	);
	app.openapi(
		createRoute({
			method: "patch",
			path,
			middleware: write,
			request: {
				params,
				body: {
					required: true,
					content: { "application/json": { schema: UpdateFundRequest } },
				},
			},
			responses: {
				200: {
					description: "Fund updated",
					content: { "application/json": { schema: MemberResponse } },
				},
			},
		}),
		async (context) =>
			context.json(
				await updateFund(deps, {
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
			middleware: write,
			request: { params },
			responses: { 204: { description: "Fund deleted" } },
		}),
		async (context) => {
			await deleteFund(deps, {
				groupId: context.var.groupAccess.groupId,
				userId: context.var.user.id,
			});
			return context.body(null, 204);
		},
	);
}
