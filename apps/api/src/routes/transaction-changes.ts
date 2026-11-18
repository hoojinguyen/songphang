import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	ApproveRejectTransactionRequest,
	TransactionResponse,
	UpdateTransactionRequest,
} from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { requireGroupRole } from "../auth/group-access.js";
import { requireSameOrigin, requireUser } from "../auth/middleware.js";
import {
	requireVerifiedEmail,
	requireWriteLimit,
} from "../auth/verified-email.js";
import { AppError } from "../errors.js";
import { decideTransactionApproval } from "../services/approval.js";
import {
	editTransaction,
	getTransaction,
	setTransactionDeleted,
} from "../services/transaction-changes.js";

const params = z.object({ groupId: z.uuid(), id: z.string().max(100) });
const response = {
	description: "Transaction",
	content: { "application/json": { schema: TransactionResponse } },
};
export function registerTransactionChangeRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
) {
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
			path: "/api/v1/groups/{groupId}/transactions/{id}",
			middleware: read,
			request: { params },
			responses: { 200: response },
		}),
		async (c) =>
			c.json(
				await getTransaction(
					deps,
					c.var.groupAccess.groupId,
					c.req.valid("param").id,
					c.var.user.id,
				),
				200,
			),
	);
	app.openapi(
		createRoute({
			method: "patch",
			path: "/api/v1/groups/{groupId}/transactions/{id}",
			middleware: write,
			request: {
				params,
				body: {
					required: true,
					content: { "application/json": { schema: UpdateTransactionRequest } },
				},
			},
			responses: { 200: response },
		}),
		async (c) =>
			c.json(
				await editTransaction(deps, {
					groupId: c.var.groupAccess.groupId,
					id: c.req.valid("param").id,
					userId: c.var.user.id,
					request: c.req.valid("json"),
				}),
				200,
			),
	);
	app.openapi(
		createRoute({
			method: "delete",
			path: "/api/v1/groups/{groupId}/transactions/{id}",
			middleware: write,
			request: { params },
			responses: { 204: { description: "Transaction deleted" } },
		}),
		async (c) => {
			await setTransactionDeleted(deps, {
				groupId: c.var.groupAccess.groupId,
				id: c.req.valid("param").id,
				userId: c.var.user.id,
				restore: false,
			});
			return c.body(null, 204);
		},
	);
	app.openapi(
		createRoute({
			method: "post",
			path: "/api/v1/groups/{groupId}/transactions/{id}/restore",
			middleware: write,
			request: { params },
			responses: { 200: response },
		}),
		async (c) =>
			c.json(
				await setTransactionDeleted(deps, {
					groupId: c.var.groupAccess.groupId,
					id: c.req.valid("param").id,
					userId: c.var.user.id,
					restore: true,
				}),
				200,
			),
	);
	const ownerWrite = [
		requireUser(deps),
		requireGroupRole(deps, "owner"),
		requireVerifiedEmail(deps),
		requireWriteLimit(deps),
		requireSameOrigin(deps.config),
	];
	async function parseOptionalApprovalBody(
		rawText: string,
	): Promise<ApproveRejectTransactionRequest> {
		if (!rawText.trim()) return {};
		let json: unknown;
		try {
			json = JSON.parse(rawText);
		} catch {
			throw new AppError(400, "VALIDATION_FAILED", "Invalid JSON body");
		}
		const parsed = ApproveRejectTransactionRequest.safeParse(json);
		if (!parsed.success) {
			throw new AppError(400, "VALIDATION_FAILED", "Validation failed");
		}
		return parsed.data;
	}
	for (const decision of ["approve", "reject"] as const) {
		app.openapi(
			createRoute({
				method: "post",
				path: `/api/v1/groups/{groupId}/transactions/{id}/${decision}`,
				middleware: ownerWrite,
				request: { params },
				responses: { 200: response },
			}),
			async (c) => {
				const body = await parseOptionalApprovalBody(await c.req.text());
				return c.json(
					await decideTransactionApproval(deps, {
						groupId: c.var.groupAccess.groupId,
						id: c.req.valid("param").id,
						userId: c.var.user.id,
						decision: decision === "approve" ? "approved" : "rejected",
						note: body.note,
					}),
					200,
				);
			},
		);
	}
}
