import { z } from "@hono/zod-openapi";
import {
	type TransactionDto,
	TransactionResponse,
	type UpdateTransactionRequest,
} from "@songphang/contract";
import { foldVietnamese } from "@songphang/core";
import {
	type AttachmentRow,
	attachToTransaction,
	clearTransactionSides,
	type DbExecutor,
	deleteRemovedTransactionAttachments,
	findTransactionRow,
	insertActivity,
	insertTransactionPayers,
	insertTransactionShares,
	lockGroup,
	lockTransaction,
	updateTransactionRow,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { getGroupAccess } from "../auth/group-access.js";
import { AppError } from "../errors.js";
import { validateTransactionAttachmentIds } from "./attachments.js";
import { assertLiveCategory } from "./categories.js";
import { calculateShares, normalizeTransaction } from "./transaction-input.js";
import { mapTransactions } from "./transactions.js";
import { transactionWarnings } from "./warnings.js";

async function readTransaction(
	executor: DbExecutor,
	groupId: string,
	id: string,
	viewerUserId: string | null = null,
) {
	if (!z.uuid().safeParse(id).success)
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	const row = await findTransactionRow(executor, groupId, id);
	if (!row) throw new AppError(404, "NOT_FOUND", "Resource not found");
	const [transaction] = await mapTransactions(
		executor,
		groupId,
		[row],
		viewerUserId,
	);
	return TransactionResponse.parse({ transaction });
}
export async function getTransaction(
	deps: AppDeps,
	groupId: string,
	id: string,
	viewerUserId: string | null = null,
) {
	return deps.db.transaction(
		(executor) => readTransaction(executor, groupId, id, viewerUserId),
		{ isolationLevel: "repeatable read", accessMode: "read only" },
	);
}
type Operation = { groupId: string; id: string; userId: string };
async function lockedTransaction(executor: DbExecutor, input: Operation) {
	await lockGroup(executor, input.groupId);
	await getGroupAccess(executor, { ...input, minimumRole: "editor" });
	if (
		!z.uuid().safeParse(input.id).success ||
		!(await lockTransaction(executor, input.groupId, input.id))
	)
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	return (
		await readTransaction(executor, input.groupId, input.id, input.userId)
	).transaction;
}
const fields = [
	"description",
	"amount",
	"occurredAt",
	"category",
	"categoryId",
	"payers",
	"shares",
	"split",
] as const;
function snapshot(transaction: TransactionDto) {
	return Object.fromEntries(
		[...fields, "type" as const].map((field) => [field, transaction[field]]),
	);
}
function publish(deps: AppDeps, groupId: string) {
	deps.events.publishChanged(groupId, [
		"transactions",
		"balances",
		"activity",
		"budget",
	]);
}
export async function editTransaction(
	deps: AppDeps,
	input: Operation & { request: UpdateTransactionRequest },
) {
	let changed = false;
	let removedFiles: AttachmentRow[] = [];
	const result = await deps.db.transaction(async (executor) => {
		const before = await lockedTransaction(executor, input);
		if (before.deletedAt)
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		if (input.request.type !== before.type)
			throw new AppError(
				400,
				"VALIDATION_FAILED",
				"Transaction type cannot change",
			);
		if (input.request.version !== before.version)
			throw new AppError(409, "VERSION_CONFLICT", "Transaction has changed", {
				current: before,
			});
		const nextAttachmentIds = input.request.attachmentIds;
		if (nextAttachmentIds !== undefined) {
			await validateTransactionAttachmentIds(
				executor,
				input.groupId,
				nextAttachmentIds,
				input.id,
			);
		}
		const shares = await calculateShares(
			executor,
			input.groupId,
			input.request,
		);
		const normalized = normalizeTransaction(input.request);
		if (
			normalized.categoryId !== null &&
			normalized.categoryId !== before.categoryId
		)
			await assertLiveCategory(executor, input.groupId, normalized.categoryId);
		const next = { ...normalized, shares };
		const altered = fields.filter(
			(field) => JSON.stringify(before[field]) !== JSON.stringify(next[field]),
		);
		const beforeAttachmentIds = before.attachments.map((a) => a.id);
		const attachmentsChanged =
			nextAttachmentIds !== undefined &&
			JSON.stringify(beforeAttachmentIds) !== JSON.stringify(nextAttachmentIds);
		if (altered.length === 0 && !attachmentsChanged) {
			return { transaction: before, warnings: [] };
		}
		changed = true;
		await clearTransactionSides(executor, input.id);
		await updateTransactionRow(executor, {
			groupId: input.groupId,
			id: input.id,
			changes: {
				description: normalized.description,
				descriptionSearch: foldVietnamese(normalized.description),
				amount: normalized.amount,
				occurredAt: new Date(normalized.occurredAt),
				category: normalized.category,
				categoryId: normalized.categoryId,
				splitMethod: normalized.split.method,
				splitInput: normalized.split,
				version: before.version + 1,
				updatedBy: input.userId,
				updatedAt: deps.now(),
			},
		});
		await insertTransactionPayers(
			executor,
			normalized.payers.map((p) => ({ ...p, transactionId: input.id })),
		);
		await insertTransactionShares(
			executor,
			shares.map((s) => ({ ...s, transactionId: input.id })),
		);
		if (nextAttachmentIds !== undefined) {
			removedFiles = await deleteRemovedTransactionAttachments(
				executor,
				input.groupId,
				input.id,
				nextAttachmentIds,
			);
			await attachToTransaction(
				executor,
				input.groupId,
				input.id,
				nextAttachmentIds,
			);
		}
		const after = (
			await readTransaction(executor, input.groupId, input.id, input.userId)
		).transaction;
		const warnings = await transactionWarnings(executor, {
			groupId: input.groupId,
			request: input.request,
			applied: true,
			now: deps.now(),
			replacing: {
				type: before.type,
				amount: before.amount,
				occurredAt: new Date(before.occurredAt),
				payers: before.payers,
			},
		});
		await insertActivity(executor, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: "update",
			entityType: "transaction",
			entityId: input.id,
			summary: after.description,
			before: {
				...Object.fromEntries(altered.map((k) => [k, before[k]])),
				...(attachmentsChanged
					? { attachmentCount: before.attachments.length }
					: {}),
			},
			after: {
				...Object.fromEntries(altered.map((k) => [k, after[k]])),
				...(attachmentsChanged
					? { attachmentCount: after.attachments.length }
					: {}),
			},
			createdAt: deps.now(),
		});
		return { transaction: after, warnings };
	});
	if (removedFiles.length > 0) {
		await Promise.allSettled(
			removedFiles.map((row) => deps.fileStore.delete(row.storageKey)),
		);
	}
	if (changed) publish(deps, input.groupId);
	return TransactionResponse.parse(result);
}
export async function setTransactionDeleted(
	deps: AppDeps,
	input: Operation & { restore: boolean },
) {
	const result = await deps.db.transaction(async (executor) => {
		const before = await lockedTransaction(executor, input);
		if (input.restore ? !before.deletedAt : !!before.deletedAt)
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		await updateTransactionRow(executor, {
			groupId: input.groupId,
			id: input.id,
			changes: {
				deletedAt: input.restore ? null : deps.now(),
				version: before.version + 1,
				updatedBy: input.userId,
				updatedAt: deps.now(),
			},
		});
		const after = (
			await readTransaction(executor, input.groupId, input.id, input.userId)
		).transaction;
		await insertActivity(executor, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: input.restore ? "restore" : "delete",
			entityType: "transaction",
			entityId: input.id,
			summary: before.description,
			before: snapshot(before),
			after: input.restore ? snapshot(after) : null,
			createdAt: deps.now(),
		});
		return { transaction: after };
	});
	publish(deps, input.groupId);
	return TransactionResponse.parse(result);
}
