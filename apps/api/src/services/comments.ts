import { z } from "@hono/zod-openapi";
import {
	CommentDto,
	CommentResponse,
	type CommentsQuery,
	CommentsResponse,
	type CreateCommentRequest,
	type UserDto,
} from "@songphang/contract";
import {
	type CommentCursor,
	type CommentRow,
	type DbExecutor,
	findCommentRow,
	findGroup,
	findTransactionRow,
	insertCommentRow,
	listCommenterUserIds,
	listCommentRows,
	listTransactionPayers,
	listTransactionShares,
	lockGroup,
	softDeleteCommentRow,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { getGroupAccess } from "../auth/group-access.js";
import { AppError } from "../errors.js";
import type { EnqueueFn } from "../queue.js";
import { assertGroupRowNotArchived } from "./group-guards.js";
import { notify } from "./notify.js";

const CURSOR_SCHEMA = z.object({ createdAt: z.iso.datetime(), id: z.uuid() });

function decodeCursor(cursor: string | undefined): CommentCursor | null {
	if (cursor === undefined) return null;
	try {
		if (!/^[A-Za-z0-9_-]+$/.test(cursor))
			throw new Error("Invalid cursor encoding");
		return CURSOR_SCHEMA.parse(
			JSON.parse(Buffer.from(cursor, "base64url").toString("utf8")),
		);
	} catch {
		throw new AppError(400, "VALIDATION_FAILED", "Invalid cursor");
	}
}

function toCommentDto(row: CommentRow, userId: string): CommentDto {
	return CommentDto.parse({
		id: row.id,
		authorUserId: row.authorUserId,
		authorName: row.authorName,
		body: row.body,
		createdAt: row.createdAt.toISOString(),
		mine: row.authorUserId !== null && row.authorUserId === userId,
	});
}

async function assertTransactionInGroup(
	executor: DbExecutor,
	groupId: string,
	transactionId: string,
) {
	if (!z.uuid().safeParse(transactionId).success)
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	const transaction = await findTransactionRow(
		executor,
		groupId,
		transactionId,
	);
	if (transaction === null)
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	return transaction;
}

export async function listComments(
	deps: AppDeps,
	input: {
		groupId: string;
		transactionId: string;
		userId: string;
		query: CommentsQuery;
	},
): Promise<CommentsResponse> {
	const cursor = decodeCursor(input.query.cursor);
	return deps.db.transaction(
		async (executor) => {
			await assertTransactionInGroup(
				executor,
				input.groupId,
				input.transactionId,
			);
			const rows = await listCommentRows(executor, {
				groupId: input.groupId,
				transactionId: input.transactionId,
				limit: input.query.limit + 1,
				cursor,
			});
			const page = rows.slice(0, input.query.limit);
			const last = page.at(-1);
			const nextCursor =
				rows.length > input.query.limit && last !== undefined
					? Buffer.from(
							JSON.stringify({
								createdAt: last.createdAt.toISOString(),
								id: last.id,
							}),
						).toString("base64url")
					: null;
			return CommentsResponse.parse({
				comments: page.map((row) => toCommentDto(row, input.userId)),
				nextCursor,
			});
		},
		{ isolationLevel: "repeatable read", accessMode: "read only" },
	);
}

export async function createComment(
	executor: DbExecutor,
	input: {
		groupId: string;
		transactionId: string;
		user: UserDto;
		request: CreateCommentRequest;
		now: Date;
		enqueue?: EnqueueFn;
		pushEnabled?: boolean;
	},
): Promise<CommentResponse> {
	const lockedGroup = await lockGroup(executor, input.groupId);
	await getGroupAccess(executor, {
		groupId: input.groupId,
		userId: input.user.id,
		minimumRole: "viewer",
	});
	assertGroupRowNotArchived(lockedGroup);
	const transaction = await assertTransactionInGroup(
		executor,
		input.groupId,
		input.transactionId,
	);
	const [group, earlierCommenters, payers, shares] = await Promise.all([
		findGroup(executor, input.groupId),
		listCommenterUserIds(executor, {
			groupId: input.groupId,
			transactionId: input.transactionId,
		}),
		listTransactionPayers(executor, input.groupId, [input.transactionId]),
		listTransactionShares(executor, input.groupId, [input.transactionId]),
	]);
	const row = await insertCommentRow(executor, {
		groupId: input.groupId,
		transactionId: input.transactionId,
		authorUserId: input.user.id,
		authorName: input.user.name,
		body: input.request.body,
		createdAt: input.now,
	});
	await notify(executor, {
		groupId: input.groupId,
		actorUserId: input.user.id,
		kind: "comment_added",
		payload: {
			kind: "comment_added",
			actorName: input.user.name,
			groupName: group?.name ?? "",
			transactionId: transaction.id,
			description: transaction.description,
		},
		toUserIds: [
			...earlierCommenters,
			...(transaction.createdBy ? [transaction.createdBy.id] : []),
		],
		toMemberIds: [
			...payers.map((payer) => payer.memberId),
			...shares.map((share) => share.memberId),
		],
		now: input.now,
		...(input.enqueue ? { enqueue: input.enqueue } : {}),
		...(input.pushEnabled === undefined
			? {}
			: { pushEnabled: input.pushEnabled }),
	});
	return CommentResponse.parse({ comment: toCommentDto(row, input.user.id) });
}

export async function deleteComment(
	deps: AppDeps,
	input: {
		groupId: string;
		transactionId: string;
		commentId: string;
		userId: string;
	},
): Promise<void> {
	if (!z.uuid().safeParse(input.commentId).success)
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	await deps.db.transaction(async (executor) => {
		const lockedGroup = await lockGroup(executor, input.groupId);
		const access = await getGroupAccess(executor, {
			groupId: input.groupId,
			userId: input.userId,
			minimumRole: "viewer",
		});
		assertGroupRowNotArchived(lockedGroup);
		await assertTransactionInGroup(
			executor,
			input.groupId,
			input.transactionId,
		);
		const comment = await findCommentRow(
			executor,
			input.groupId,
			input.transactionId,
			input.commentId,
		);
		if (comment === null)
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		if (comment.authorUserId !== input.userId && access.role !== "owner")
			throw new AppError(403, "FORBIDDEN", "Insufficient group role");
		await softDeleteCommentRow(executor, {
			groupId: input.groupId,
			transactionId: input.transactionId,
			commentId: input.commentId,
			deletedAt: deps.now(),
		});
	});
	deps.events.publishChanged(input.groupId, ["comments", "transactions"]);
}
