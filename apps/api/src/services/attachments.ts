import { createHash } from "node:crypto";
import { z } from "@hono/zod-openapi";
import {
	type AttachmentContentType,
	AttachmentDto,
	AttachmentResponse,
	type AttachmentUploadPurpose,
} from "@songphang/contract";
import type { DbExecutor } from "@songphang/db";
import {
	type AttachmentRow,
	deleteAttachmentRow,
	findAttachment,
	findAttachmentsByIds,
	findSettlementRequestByProofAttachmentId,
	findTransactionRow,
	insertActivity,
	insertAttachment,
	listAttachmentsForTransactions,
	lockGroup,
	lockTransaction,
	sumGroupAttachmentBytes,
	updateTransactionRow,
} from "@songphang/db";
import { uuidv7 } from "uuidv7";
import type { AppDeps } from "../app.js";
import { getGroupAccess } from "../auth/group-access.js";
import { AppError } from "../errors.js";
import { assertGroupRowNotArchived } from "./group-guards.js";

const GROUP_QUOTA_BYTES = 209_715_200; // 200 MiB

export function toAttachmentDto(row: AttachmentRow): AttachmentDto {
	return AttachmentDto.parse({
		id: row.id,
		contentType: row.contentType,
		byteSize: row.byteSize,
		transactionId: row.transactionId,
		createdAt: row.createdAt.toISOString(),
	});
}

export async function validateTransactionAttachmentIds(
	executor: DbExecutor,
	groupId: string,
	attachmentIds: string[],
	currentTransactionId: string | null,
): Promise<void> {
	if (attachmentIds.length === 0) return;
	const rows = await findAttachmentsByIds(executor, groupId, attachmentIds);
	if (rows.length !== attachmentIds.length) {
		throw new AppError(400, "VALIDATION_FAILED", "Invalid attachment IDs");
	}
	for (const row of rows) {
		if (
			row.transactionId !== null &&
			row.transactionId !== currentTransactionId
		) {
			throw new AppError(
				400,
				"VALIDATION_FAILED",
				"Attachment already belongs to another transaction",
			);
		}
	}
}

export async function uploadAttachment(
	deps: AppDeps,
	input: {
		groupId: string;
		userId: string;
		bytes: Uint8Array;
		contentType: AttachmentContentType;
		purpose?: AttachmentUploadPurpose;
	},
) {
	const id = uuidv7();
	const storageKey = `${input.groupId}/${id}`;
	const sha256 = createHash("sha256").update(input.bytes).digest("hex");
	const createdAt = deps.now();
	const purpose = input.purpose ?? "expense";

	const row = await deps.db.transaction(async (executor) => {
		const lockedGroup = await lockGroup(executor, input.groupId);
		const access = await getGroupAccess(executor, {
			groupId: input.groupId,
			userId: input.userId,
			minimumRole: "viewer",
		});
		if (
			access.role === "viewer" &&
			(purpose !== "transfer_proof" || access.memberId === null)
		) {
			throw new AppError(403, "FORBIDDEN", "Insufficient group role");
		}
		assertGroupRowNotArchived(lockedGroup);
		const used = await sumGroupAttachmentBytes(executor, input.groupId);
		if (used + input.bytes.byteLength > GROUP_QUOTA_BYTES) {
			throw new AppError(
				422,
				"STORAGE_QUOTA_EXCEEDED",
				"Group storage quota exceeded",
			);
		}
		await deps.fileStore.put(storageKey, input.bytes, input.contentType);
		try {
			return await insertAttachment(executor, {
				id,
				groupId: input.groupId,
				storageKey,
				contentType: input.contentType,
				byteSize: input.bytes.byteLength,
				sha256,
				uploadedBy: input.userId,
				createdAt,
			});
		} catch (error) {
			await deps.fileStore.delete(storageKey).catch(() => {});
			throw error;
		}
	});

	return AttachmentResponse.parse({ attachment: toAttachmentDto(row) });
}

export async function getAttachmentContent(
	deps: AppDeps,
	input: { groupId: string; id: string; userId: string },
): Promise<{ bytes: Uint8Array; contentType: string }> {
	const parsedId = z.uuid().safeParse(input.id);
	if (!parsedId.success) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	await getGroupAccess(deps.db, {
		groupId: input.groupId,
		userId: input.userId,
		minimumRole: "viewer",
	});
	const row = await findAttachment(deps.db, input.groupId, parsedId.data);
	if (row === null) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	const bytes = await deps.fileStore.get(row.storageKey);
	if (bytes === null) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	return { bytes, contentType: row.contentType };
}

export async function deleteAttachment(
	deps: AppDeps,
	input: { groupId: string; id: string; userId: string },
): Promise<void> {
	const parsedId = z.uuid().safeParse(input.id);
	if (!parsedId.success) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	const row = await deps.db.transaction(async (executor) => {
		const lockedGroup = await lockGroup(executor, input.groupId);
		const access = await getGroupAccess(executor, {
			groupId: input.groupId,
			userId: input.userId,
			minimumRole: "viewer",
		});
		assertGroupRowNotArchived(lockedGroup);
		const existing = await findAttachment(
			executor,
			input.groupId,
			parsedId.data,
		);
		if (existing === null) {
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		}
		if (access.role === "viewer") {
			if (
				existing.uploadedBy !== input.userId ||
				existing.transactionId !== null
			) {
				throw new AppError(403, "FORBIDDEN", "Insufficient group role");
			}
			const linkedRequest = await findSettlementRequestByProofAttachmentId(
				executor,
				input.groupId,
				existing.id,
			);
			if (linkedRequest?.status === "pending") {
				throw new AppError(
					409,
					"REQUEST_ALREADY_PENDING",
					"Attachment is bound to a pending settlement request",
				);
			}
		}
		if (existing.transactionId !== null) {
			await lockTransaction(executor, input.groupId, existing.transactionId);
			const txRow = await findTransactionRow(
				executor,
				input.groupId,
				existing.transactionId,
			);
			const beforeCount = (
				await listAttachmentsForTransactions(executor, input.groupId, [
					existing.transactionId,
				])
			).length;
			const deleted = await deleteAttachmentRow(
				executor,
				input.groupId,
				parsedId.data,
			);
			if (deleted === null) {
				throw new AppError(404, "NOT_FOUND", "Resource not found");
			}
			if (txRow) {
				await updateTransactionRow(executor, {
					groupId: input.groupId,
					id: txRow.id,
					changes: {
						version: txRow.version + 1,
						updatedBy: input.userId,
						updatedAt: deps.now(),
					},
				});
				await insertActivity(executor, {
					groupId: input.groupId,
					actorUserId: input.userId,
					action: "update",
					entityType: "transaction",
					entityId: txRow.id,
					summary: txRow.description,
					before: { attachmentCount: beforeCount },
					after: { attachmentCount: Math.max(0, beforeCount - 1) },
					createdAt: deps.now(),
				});
			}
			return deleted;
		}
		const deleted = await deleteAttachmentRow(
			executor,
			input.groupId,
			parsedId.data,
		);
		if (deleted === null) {
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		}
		return deleted;
	});
	await deps.fileStore.delete(row.storageKey).catch(() => {});
	deps.events.publishChanged(
		input.groupId,
		row.transactionId !== null
			? ["transactions", "activity", "receiptScans"]
			: ["receiptScans"],
	);
}
