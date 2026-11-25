import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	CreateSettlementCycleRequest,
	IdempotencyKeyHeader,
	SettlementCycleResponse,
	SettlementCyclesResponse,
} from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { requireGroupRole } from "../auth/group-access.js";
import { requireSameOrigin, requireUser } from "../auth/middleware.js";
import {
	requireVerifiedEmail,
	requireWriteLimit,
} from "../auth/verified-email.js";
import { AppError } from "../errors.js";
import { hashRequest, runIdempotent } from "../idempotency.js";
import {
	createSettlementCycle,
	getSettlementCycles,
	reopenSettlementCycle,
} from "../services/settlement-cycles.js";

const params = z.object({ groupId: z.uuid() });
const cycleParams = params.extend({ cycleId: z.string().max(100) });

async function parseOptionalCreateBody(
	rawText: string,
): Promise<CreateSettlementCycleRequest> {
	if (!rawText.trim()) return {};
	let json: unknown;
	try {
		json = JSON.parse(rawText);
	} catch {
		throw new AppError(400, "VALIDATION_FAILED", "Invalid JSON body");
	}
	const parsed = CreateSettlementCycleRequest.safeParse(json);
	if (!parsed.success) {
		throw new AppError(400, "VALIDATION_FAILED", "Validation failed");
	}
	return parsed.data;
}

export function registerSettlementCycleRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	const read = [requireUser(deps), requireGroupRole(deps, "viewer")];
	const editorWrite = [
		requireUser(deps),
		requireGroupRole(deps, "editor"),
		requireVerifiedEmail(deps),
		requireWriteLimit(deps),
		requireSameOrigin(deps.config),
	];
	const ownerWrite = [
		requireUser(deps),
		requireGroupRole(deps, "owner"),
		requireVerifiedEmail(deps),
		requireWriteLimit(deps),
		requireSameOrigin(deps.config),
	];

	app.openapi(
		createRoute({
			method: "get",
			path: "/api/v1/groups/{groupId}/settlement-cycles",
			middleware: read,
			request: { params },
			responses: {
				200: {
					description: "Closed settlement cycles and current period summary",
					content: {
						"application/json": { schema: SettlementCyclesResponse },
					},
				},
			},
		}),
		async (context) =>
			context.json(
				await getSettlementCycles(deps, context.var.groupAccess.groupId),
				200,
			),
	);

	app.openapi(
		createRoute({
			method: "post",
			path: "/api/v1/groups/{groupId}/settlement-cycles",
			middleware: editorWrite,
			request: {
				params,
				headers: z.object({ "idempotency-key": IdempotencyKeyHeader }),
				body: {
					required: false,
					content: {
						"application/json": { schema: CreateSettlementCycleRequest },
					},
				},
			},
			responses: {
				201: {
					description: "Settlement cycle closed",
					content: {
						"application/json": { schema: SettlementCycleResponse },
					},
				},
			},
		}),
		async (context) => {
			const request = await parseOptionalCreateBody(await context.req.text());
			const response = await runIdempotent(
				deps,
				{
					userId: context.var.user.id,
					key: context.req.valid("header")["idempotency-key"],
					requestHash: hashRequest("POST", context.req.path, request),
					onCommitted: () =>
						deps.events.publishChanged(context.var.groupAccess.groupId, [
							"group",
							"transactions",
							"activity",
							"settlementCycles",
						]),
				},
				async (executor) => ({
					status: 201,
					body: await createSettlementCycle(executor, {
						groupId: context.var.groupAccess.groupId,
						userId: context.var.user.id,
						request,
						now: deps.now(),
					}),
				}),
			);
			return context.json(SettlementCycleResponse.parse(response.body), 201);
		},
	);

	app.openapi(
		createRoute({
			method: "delete",
			path: "/api/v1/groups/{groupId}/settlement-cycles/{cycleId}",
			middleware: ownerWrite,
			request: { params: cycleParams },
			responses: {
				204: { description: "Latest settlement cycle reopened" },
			},
		}),
		async (context) => {
			await reopenSettlementCycle(deps, {
				groupId: context.var.groupAccess.groupId,
				userId: context.var.user.id,
				cycleId: context.req.valid("param").cycleId,
			});
			return context.body(null, 204);
		},
	);
}
