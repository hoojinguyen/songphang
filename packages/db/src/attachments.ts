import { and, eq, sql } from "drizzle-orm";
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
