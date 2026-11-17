import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	CreateReceiptScanRequest,
	IdempotencyKeyHeader,
	ReceiptScanResponse,
} from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { requireGroupRole } from "../auth/group-access.js";
import { requireSameOrigin, requireUser } from "../auth/middleware.js";
import {
	requireVerifiedEmail,
	requireWriteLimit,
} from "../auth/verified-email.js";
import { hashRequest } from "../idempotency.js";
import {
	createReceiptScan,
	getReceiptScan,
} from "../services/receipt-scans.js";

const groupParams = z.object({ groupId: z.uuid() });
const itemParams = groupParams.extend({ id: z.string().max(100) });

export function registerReceiptScanRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	app.openapi(
		createRoute({
			method: "post",
			path: "/api/v1/groups/{groupId}/receipt-scans",
			middleware: [
				requireUser(deps),
				requireGroupRole(deps, "editor"),
				requireVerifiedEmail(deps),
				requireSameOrigin(deps.config),
				requireWriteLimit(deps),
			],
			request: {
				params: groupParams,
				headers: z.object({ "idempotency-key": IdempotencyKeyHeader }),
				body: {
					required: true,
					content: { "application/json": { schema: CreateReceiptScanRequest } },
				},
			},
			responses: {
				200: {
					description: "Existing receipt scan",
					content: { "application/json": { schema: ReceiptScanResponse } },
				},
				201: {
					description: "Receipt scan queued",
					content: { "application/json": { schema: ReceiptScanResponse } },
				},
			},
		}),
		async (context) => {
			const request = context.req.valid("json");
			const result = await createReceiptScan(deps, {
				groupId: context.var.groupAccess.groupId,
				userId: context.var.user.id,
				idempotencyKey: context.req.valid("header")["idempotency-key"],
				requestHash: hashRequest("POST", context.req.path, request),
				request,
			});
			return context.json(result.body, result.status);
		},
	);

	app.openapi(
		createRoute({
			method: "get",
			path: "/api/v1/groups/{groupId}/receipt-scans/{id}",
			middleware: [requireUser(deps), requireGroupRole(deps, "viewer")],
			request: { params: itemParams },
			responses: {
				200: {
					description: "Receipt scan status and reading",
					content: { "application/json": { schema: ReceiptScanResponse } },
				},
			},
		}),
		async (context) => {
			const body = await getReceiptScan(deps, {
				groupId: context.var.groupAccess.groupId,
				scanId: context.req.valid("param").id,
			});
			return context.json(body, 200);
		},
	);
}
