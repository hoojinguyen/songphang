import { and, eq, gte, inArray, lt, notExists } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { aiCalls } from "./schema-ai.js";
import { receiptScans, type StoredReceiptScanResult } from "./schema-scans.js";

export type ReceiptScanRow = typeof receiptScans.$inferSelect;

export async function insertReceiptScan(
	executor: DbExecutor,
	input: {
		id: string;
		groupId: string;
		attachmentId: string;
		createdBy: string;
		createdAt: Date;
	},
): Promise<ReceiptScanRow> {
	const [row] = await executor
		.insert(receiptScans)
		.values({
			id: input.id,
			groupId: input.groupId,
			attachmentId: input.attachmentId,
			status: "queued",
			createdBy: input.createdBy,
			createdAt: input.createdAt,
		})
		.returning();
	if (!row) throw new Error("Failed to insert receipt scan");
	return row;
}

export async function findReceiptScan(
	executor: DbExecutor,
	groupId: string,
	scanId: string,
): Promise<ReceiptScanRow | null> {
	const [row] = await executor
		.select()
		.from(receiptScans)
		.where(and(eq(receiptScans.groupId, groupId), eq(receiptScans.id, scanId)))
		.limit(1);
	return row ?? null;
}

export async function findReceiptScanById(
	executor: DbExecutor,
	scanId: string,
): Promise<ReceiptScanRow | null> {
	const [row] = await executor
		.select()
		.from(receiptScans)
		.where(eq(receiptScans.id, scanId))
		.limit(1);
	return row ?? null;
}

export async function findReceiptScanByAttachment(
	executor: DbExecutor,
	groupId: string,
	attachmentId: string,
): Promise<ReceiptScanRow | null> {
	const [row] = await executor
		.select()
		.from(receiptScans)
		.where(
			and(
				eq(receiptScans.groupId, groupId),
				eq(receiptScans.attachmentId, attachmentId),
			),
		)
		.limit(1);
	return row ?? null;
}

export async function markReceiptScanProcessing(
	executor: DbExecutor,
	scanId: string,
): Promise<ReceiptScanRow | null> {
	const [row] = await executor
		.update(receiptScans)
		.set({ status: "processing" })
		.where(
			and(
				eq(receiptScans.id, scanId),
				inArray(receiptScans.status, ["queued", "processing"]),
			),
		)
		.returning();
	return row ?? null;
}

export async function finishReceiptScanDone(
	executor: DbExecutor,
	input: {
		scanId: string;
		result: StoredReceiptScanResult;
		finishedAt: Date;
	},
): Promise<ReceiptScanRow | null> {
	const [row] = await executor
		.update(receiptScans)
		.set({
			status: "done",
			result: input.result,
			errorCode: null,
			finishedAt: input.finishedAt,
		})
		.where(
			and(
				eq(receiptScans.id, input.scanId),
				inArray(receiptScans.status, ["queued", "processing"]),
			),
		)
		.returning();
	return row ?? null;
}

export async function finishReceiptScanFailed(
	executor: DbExecutor,
	input: {
		scanId: string;
		errorCode: string;
		finishedAt: Date;
	},
): Promise<ReceiptScanRow | null> {
	const [row] = await executor
		.update(receiptScans)
		.set({
			status: "failed",
			result: null,
			errorCode: input.errorCode,
			finishedAt: input.finishedAt,
		})
		.where(
			and(
				eq(receiptScans.id, input.scanId),
				inArray(receiptScans.status, ["queued", "processing"]),
			),
		)
		.returning();
	return row ?? null;
}

export async function failStaleProcessingScans(
	executor: DbExecutor,
	input: { cutoff: Date; finishedAt: Date; errorCode: string },
): Promise<Array<{ id: string; groupId: string }>> {
	return executor
		.update(receiptScans)
		.set({
			status: "failed",
			result: null,
			errorCode: input.errorCode,
			finishedAt: input.finishedAt,
		})
		.where(
			and(
				eq(receiptScans.status, "processing"),
				lt(receiptScans.createdAt, input.cutoff),
				notExists(
					executor
						.select({ id: aiCalls.id })
						.from(aiCalls)
						.where(
							and(
								eq(aiCalls.receiptScanId, receiptScans.id),
								gte(aiCalls.startedAt, input.cutoff),
							),
						),
				),
			),
		)
		.returning({ id: receiptScans.id, groupId: receiptScans.groupId });
}
