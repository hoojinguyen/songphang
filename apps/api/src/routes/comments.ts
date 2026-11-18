import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	CommentResponse,
	CommentsQuery,
	CommentsResponse,
	CreateCommentRequest,
	DisputeResponse,
	IdempotencyKeyHeader,
	OpenDisputeRequest,
} from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { requireGroupRole } from "../auth/group-access.js";
import { requireSameOrigin, requireUser } from "../auth/middleware.js";
import {
	requireVerifiedEmail,
	requireWriteLimit,
} from "../auth/verified-email.js";
import { hashRequest, runIdempotent } from "../idempotency.js";
import { requireCommentLimit } from "../rate-limit.js";
import {
	createComment,
	deleteComment,
	listComments,
} from "../services/comments.js";
import { openDispute, resolveDispute } from "../services/disputes.js";

const transactionParams = z.object({
	groupId: z.uuid(),
	id: z.string().max(100),
});
const commentParams = transactionParams.extend({
	commentId: z.string().max(100),
});

export function registerCommentRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	const read = [requireUser(deps), requireGroupRole(deps, "viewer")];
	const write = [
		...read,
		requireVerifiedEmail(deps),
		requireSameOrigin(deps.config),
		requireWriteLimit(deps),
	];

	app.openapi(
		createRoute({
			method: "get",
			path: "/api/v1/groups/{groupId}/transactions/{id}/comments",
			middleware: read,
			request: { params: transactionParams, query: CommentsQuery },
			responses: {
				200: {
					description: "Transaction comments",
					content: { "application/json": { schema: CommentsResponse } },
				},
			},
		}),
		async (context) =>
			context.json(
				await listComments(deps, {
					groupId: context.var.groupAccess.groupId,
					transactionId: context.req.valid("param").id,
					userId: context.var.user.id,
					query: context.req.valid("query"),
				}),
				200,
			),
	);

	app.openapi(
		createRoute({
			method: "post",
			path: "/api/v1/groups/{groupId}/transactions/{id}/comments",
			middleware: [...write, requireCommentLimit(deps)],
			request: {
				params: transactionParams,
				headers: z.object({ "idempotency-key": IdempotencyKeyHeader }),
				body: {
					required: true,
					content: { "application/json": { schema: CreateCommentRequest } },
				},
			},
			responses: {
				201: {
					description: "Comment created",
					content: { "application/json": { schema: CommentResponse } },
				},
			},
		}),
		async (context) => {
			const request = context.req.valid("json");
			const groupId = context.var.groupAccess.groupId;
			const transactionId = context.req.valid("param").id;
			const response = await runIdempotent(
				deps,
				{
					userId: context.var.user.id,
					key: context.req.valid("header")["idempotency-key"],
					onCommitted: () =>
						deps.events.publishChanged(groupId, ["comments", "transactions"]),
					requestHash: hashRequest("POST", context.req.path, request),
				},
				async (executor) => ({
					status: 201,
					body: await createComment(executor, {
						groupId,
						transactionId,
						user: context.var.user,
						request,
						now: deps.now(),
					}),
				}),
			);
			return context.json(CommentResponse.parse(response.body), 201);
		},
	);

	app.openapi(
		createRoute({
			method: "delete",
			path: "/api/v1/groups/{groupId}/transactions/{id}/comments/{commentId}",
			middleware: write,
			request: { params: commentParams },
			responses: {
				204: { description: "Comment deleted" },
			},
		}),
		async (context) => {
			const { id, commentId } = context.req.valid("param");
			await deleteComment(deps, {
				groupId: context.var.groupAccess.groupId,
				transactionId: id,
				commentId,
				userId: context.var.user.id,
			});
			return context.body(null, 204);
		},
	);

	app.openapi(
		createRoute({
			method: "post",
			path: "/api/v1/groups/{groupId}/transactions/{id}/dispute",
			middleware: write,
			request: {
				params: transactionParams,
				body: {
					required: true,
					content: { "application/json": { schema: OpenDisputeRequest } },
				},
			},
			responses: {
				201: {
					description: "Dispute opened",
					content: { "application/json": { schema: DisputeResponse } },
				},
			},
		}),
		async (context) =>
			context.json(
				await openDispute(deps, {
					groupId: context.var.groupAccess.groupId,
					transactionId: context.req.valid("param").id,
					user: context.var.user,
					request: context.req.valid("json"),
				}),
				201,
			),
	);

	app.openapi(
		createRoute({
			method: "post",
			path: "/api/v1/groups/{groupId}/transactions/{id}/dispute/resolve",
			middleware: write,
			request: { params: transactionParams },
			responses: {
				200: {
					description: "Dispute resolved",
					content: { "application/json": { schema: DisputeResponse } },
				},
			},
		}),
		async (context) =>
			context.json(
				await resolveDispute(deps, {
					groupId: context.var.groupAccess.groupId,
					transactionId: context.req.valid("param").id,
					userId: context.var.user.id,
				}),
				200,
			),
	);
}
