import {
	and,
	asc,
	eq,
	inArray,
	isNull,
	lt,
	notInArray,
	sql,
} from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { attachments } from "./schema-attachments.js";

export type AttachmentRow = typeof attachments.$inferSelect;

export async function sumGroupAttachmentBytes(
	executor: DbExecutor,
	groupId: string,
): Promise<number> {
	const [row] = await executor
		.select({
			total: sql<string>`coalesce(sum(${attachments.byteSize}), 0)::text`,
		})
		.from(attachments)
		.where(eq(attachments.groupId, groupId));
	return Number(row?.total ?? "0");
}

export async function insertAttachment(
	executor: DbExecutor,
	input: {
		id: string;
		groupId: string;
		storageKey: string;
		contentType: string;
		byteSize: number;
		sha256: string;
		uploadedBy: string;
		createdAt: Date;
	},
): Promise<AttachmentRow> {
	const [row] = await executor.insert(attachments).values(input).returning();
	if (!row) throw new Error("Failed to insert attachment");
	return row;
}

export async function findAttachment(
	executor: DbExecutor,
	groupId: string,
	id: string,
): Promise<AttachmentRow | null> {
	const [row] = await executor
		.select()
		.from(attachments)
		.where(and(eq(attachments.groupId, groupId), eq(attachments.id, id)))
		.limit(1);
	return row ?? null;
}

export async function findAttachmentByStorageKey(
	executor: DbExecutor,
	storageKey: string,
): Promise<AttachmentRow | null> {
	const [row] = await executor
		.select()
		.from(attachments)
		.where(eq(attachments.storageKey, storageKey))
		.limit(1);
	return row ?? null;
}

export async function findAttachmentsByIds(
	executor: DbExecutor,
	groupId: string,
	ids: string[],
): Promise<AttachmentRow[]> {
	if (ids.length === 0) return [];
	return executor
		.select()
		.from(attachments)
		.where(and(eq(attachments.groupId, groupId), inArray(attachments.id, ids)));
}

export async function listAttachmentsForTransactions(
	executor: DbExecutor,
	groupId: string,
	transactionIds: string[],
): Promise<AttachmentRow[]> {
	if (transactionIds.length === 0) return [];
	return executor
		.select()
		.from(attachments)
		.where(
			and(
				eq(attachments.groupId, groupId),
				inArray(attachments.transactionId, transactionIds),
			),
		)
		.orderBy(asc(attachments.createdAt), asc(attachments.id));
}

export async function countAttachmentsForTransactions(
	executor: DbExecutor,
	groupId: string,
	transactionIds: string[],
): Promise<Map<string, number>> {
	if (transactionIds.length === 0) return new Map();
	const rows = await executor
		.select({
			transactionId: attachments.transactionId,
			count: sql<number>`count(*)::int`,
		})
		.from(attachments)
		.where(
			and(
				eq(attachments.groupId, groupId),
				inArray(attachments.transactionId, transactionIds),
			),
		)
		.groupBy(attachments.transactionId);
	const counts = new Map<string, number>();
	for (const row of rows) {
		if (row.transactionId !== null) {
			counts.set(row.transactionId, row.count);
		}
	}
	return counts;
}

export async function attachToTransaction(
	executor: DbExecutor,
	groupId: string,
	transactionId: string,
	ids: string[],
): Promise<void> {
	if (ids.length === 0) return;
	await executor
		.update(attachments)
		.set({ transactionId })
		.where(and(eq(attachments.groupId, groupId), inArray(attachments.id, ids)));
}

export async function deleteRemovedTransactionAttachments(
	executor: DbExecutor,
	groupId: string,
	transactionId: string,
	keepIds: string[],
): Promise<AttachmentRow[]> {
	return executor
		.delete(attachments)
		.where(
			and(
				eq(attachments.groupId, groupId),
				eq(attachments.transactionId, transactionId),
				keepIds.length > 0 ? notInArray(attachments.id, keepIds) : undefined,
			),
		)
		.returning();
}

export async function deleteAttachmentRow(
	executor: DbExecutor,
	groupId: string,
	id: string,
): Promise<AttachmentRow | null> {
	const [row] = await executor
		.delete(attachments)
		.where(and(eq(attachments.groupId, groupId), eq(attachments.id, id)))
		.returning();
	return row ?? null;
}

export async function listGroupAttachmentKeys(
	executor: DbExecutor,
	groupId: string,
): Promise<string[]> {
	const rows = await executor
		.select({ storageKey: attachments.storageKey })
		.from(attachments)
		.where(eq(attachments.groupId, groupId));
	return rows.map((row) => row.storageKey);
}

export async function listStaleUnattachedGroups(
	executor: DbExecutor,
	cutoff: Date,
): Promise<string[]> {
	const rows = await executor
		.selectDistinct({ groupId: attachments.groupId })
		.from(attachments)
		.where(
			and(isNull(attachments.transactionId), lt(attachments.createdAt, cutoff)),
		);
	return rows.map((row) => row.groupId);
}

export async function deleteStaleUnattachedForGroup(
	executor: DbExecutor,
	groupId: string,
	cutoff: Date,
): Promise<string[]> {
	const rows = await executor
		.delete(attachments)
		.where(
			and(
				eq(attachments.groupId, groupId),
				isNull(attachments.transactionId),
				lt(attachments.createdAt, cutoff),
			),
		)
		.returning({ storageKey: attachments.storageKey });
	return rows.map((row) => row.storageKey);
}
