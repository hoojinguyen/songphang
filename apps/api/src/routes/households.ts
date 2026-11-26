import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	CreateHouseholdRequest,
	HouseholdResponse,
	HouseholdsResponse,
	IdempotencyKeyHeader,
	UpdateHouseholdRequest,
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
	createHousehold,
	editHousehold,
	listHouseholds,
	removeHousehold,
} from "../services/households.js";

const params = z.object({ groupId: z.uuid() });
const householdParams = params.extend({ householdId: z.string().max(100) });

export function registerHouseholdRoutes(
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
			path: "/api/v1/groups/{groupId}/households",
			middleware: read,
			request: { params },
			responses: {
				200: {
					description: "Group households",
					content: { "application/json": { schema: HouseholdsResponse } },
				},
			},
		}),
		async (context) =>
			context.json(
				await listHouseholds(deps, context.var.groupAccess.groupId),
				200,
			),
	);

	app.openapi(
		createRoute({
			method: "post",
			path: "/api/v1/groups/{groupId}/households",
			middleware: write,
			request: {
				params,
				headers: z.object({ "idempotency-key": IdempotencyKeyHeader }),
				body: {
					required: true,
					content: { "application/json": { schema: CreateHouseholdRequest } },
				},
			},
			responses: {
				201: {
					description: "Household created",
					content: { "application/json": { schema: HouseholdResponse } },
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
							"members",
							"balances",
							"households",
							"activity",
						]),
					requestHash: hashRequest("POST", context.req.path, request),
				},
				async (executor) => ({
					status: 201,
					body: await createHousehold(executor, {
						groupId: context.var.groupAccess.groupId,
						userId: context.var.user.id,
						request,
						now: deps.now(),
					}),
				}),
			);
			return context.json(HouseholdResponse.parse(response.body), 201);
		},
	);

	app.openapi(
		createRoute({
			method: "patch",
			path: "/api/v1/groups/{groupId}/households/{householdId}",
			middleware: write,
			request: {
				params: householdParams,
				body: {
					required: true,
					content: { "application/json": { schema: UpdateHouseholdRequest } },
				},
			},
			responses: {
				200: {
					description: "Household updated",
					content: { "application/json": { schema: HouseholdResponse } },
				},
			},
		}),
		async (context) =>
			context.json(
				await editHousehold(deps, {
					groupId: context.var.groupAccess.groupId,
					userId: context.var.user.id,
					householdId: context.req.valid("param").householdId,
					request: context.req.valid("json"),
				}),
				200,
			),
	);

	app.openapi(
		createRoute({
			method: "delete",
			path: "/api/v1/groups/{groupId}/households/{householdId}",
			middleware: write,
			request: { params: householdParams },
			responses: {
				204: { description: "Household deleted" },
			},
		}),
		async (context) => {
			await removeHousehold(deps, {
				groupId: context.var.groupAccess.groupId,
				userId: context.var.user.id,
				householdId: context.req.valid("param").householdId,
			});
			return context.body(null, 204);
		},
	);
}
