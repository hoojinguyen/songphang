import {
	and,
	asc,
	eq,
	gt,
	inArray,
	isNotNull,
	isNull,
	or,
	sql,
} from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { comments } from "./schema-comments.js";

export type CommentRow = typeof comments.$inferSelect;
export type CommentCursor = { createdAt: string; id: string };

export function listCommentRows(
	executor: DbExecutor,
	input: {
		groupId: string;
		transactionId: string;
		limit: number;
		cursor: CommentCursor | null;
	},
): Promise<CommentRow[]> {
	const cursor = input.cursor;
	return executor
		.select()
		.from(comments)
		.where(
			and(
				eq(comments.groupId, input.groupId),
				eq(comments.transactionId, input.transactionId),
				isNull(comments.deletedAt),
				cursor === null
					? undefined
					: or(
							gt(comments.createdAt, new Date(cursor.createdAt)),
							and(
								eq(comments.createdAt, new Date(cursor.createdAt)),
								gt(comments.id, cursor.id),
							),
						),
			),
		)
		.orderBy(asc(comments.createdAt), asc(comments.id))
		.limit(input.limit);
}

export async function findCommentRow(
	executor: DbExecutor,
	groupId: string,
	transactionId: string,
	commentId: string,
): Promise<CommentRow | null> {
	const [row] = await executor
		.select()
		.from(comments)
		.where(
			and(
				eq(comments.groupId, groupId),
				eq(comments.transactionId, transactionId),
				eq(comments.id, commentId),
				isNull(comments.deletedAt),
			),
		)
		.limit(1);
	return row ?? null;
}

export async function insertCommentRow(
	executor: DbExecutor,
	input: {
		groupId: string;
		transactionId: string;
		authorUserId: string;
		authorName: string;
		body: string;
		createdAt: Date;
	},
): Promise<CommentRow> {
	const [row] = await executor.insert(comments).values(input).returning();
	if (!row) throw new Error("Failed to insert comment");
	return row;
}

export async function softDeleteCommentRow(
	executor: DbExecutor,
	input: {
		groupId: string;
		transactionId: string;
		commentId: string;
		deletedAt: Date;
	},
): Promise<void> {
	await executor
		.update(comments)
		.set({ deletedAt: input.deletedAt })
		.where(
			and(
				eq(comments.groupId, input.groupId),
				eq(comments.transactionId, input.transactionId),
				eq(comments.id, input.commentId),
				isNull(comments.deletedAt),
			),
		);
}

export async function countCommentsForTransactions(
	executor: DbExecutor,
	groupId: string,
	transactionIds: string[],
): Promise<Map<string, number>> {
	if (transactionIds.length === 0) return new Map();
	const rows = await executor
		.select({
			transactionId: comments.transactionId,
			count: sql<number>`count(*)::int`,
		})
		.from(comments)
		.where(
			and(
				eq(comments.groupId, groupId),
				inArray(comments.transactionId, transactionIds),
				isNull(comments.deletedAt),
			),
		)
		.groupBy(comments.transactionId);
	return new Map(rows.map((row) => [row.transactionId, row.count]));
}

export async function listTransactionCommentAuthorIds(
	executor: DbExecutor,
	groupId: string,
	transactionId: string,
): Promise<string[]> {
	const rows = await executor
		.selectDistinct({ authorUserId: comments.authorUserId })
		.from(comments)
		.where(
			and(
				eq(comments.groupId, groupId),
				eq(comments.transactionId, transactionId),
				isNull(comments.deletedAt),
				isNotNull(comments.authorUserId),
			),
		);
	return rows.flatMap((row) =>
		row.authorUserId === null ? [] : [row.authorUserId],
	);
}
