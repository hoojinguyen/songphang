import { z } from "@hono/zod-openapi";
import {
	type TransactionDto,
	TransactionResponse,
	type UpdateTransactionRequest,
} from "@songphang/contract";
import {
	clearTransactionSides,
	type DbExecutor,
	findGroupAccess,
	findTransactionRow,
	insertActivity,
	insertTransactionPayers,
	insertTransactionShares,
	lockGroup,
	lockTransaction,
	updateTransactionRow,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { AppError } from "../errors.js";
import { calculateShares, normalizeTransaction } from "./transaction-input.js";
import { mapTransactions } from "./transactions.js";
export async function getTransaction(
	executor: DbExecutor,
	groupId: string,
	id: string,
) {
	if (!z.uuid().safeParse(id).success)
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	const row = await findTransactionRow(executor, groupId, id);
	if (!row) throw new AppError(404, "NOT_FOUND", "Resource not found");
	const [transaction] = await mapTransactions(executor, groupId, [row]);
	return TransactionResponse.parse({ transaction });
}
type Operation = { groupId: string; id: string; userId: string };
async function lockedTransaction(executor: DbExecutor, input: Operation) {
	await lockGroup(executor, input.groupId);
	const access = await findGroupAccess(executor, input.groupId, input.userId);
	if (!access) throw new AppError(404, "NOT_FOUND", "Resource not found");
	if (access.role === "viewer")
		throw new AppError(403, "FORBIDDEN", "Insufficient group role");
	if (
		!z.uuid().safeParse(input.id).success ||
		!(await lockTransaction(executor, input.groupId, input.id))
	)
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	return (await getTransaction(executor, input.groupId, input.id)).transaction;
}
const fields = [
	"description",
	"amount",
	"occurredAt",
	"category",
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
	deps.events.publishChanged(groupId, ["transactions", "balances", "activity"]);
}
export async function editTransaction(
	deps: AppDeps,
	input: Operation & { request: UpdateTransactionRequest },
) {
	let changed = false;
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
		const shares = await calculateShares(
			executor,
			input.groupId,
			input.request,
		);
		const normalized = normalizeTransaction(input.request);
		const next = { ...normalized, shares };
		const altered = fields.filter(
			(field) => JSON.stringify(before[field]) !== JSON.stringify(next[field]),
		);
		if (altered.length === 0) return { transaction: before };
		changed = true;
		await clearTransactionSides(executor, input.id);
		await updateTransactionRow(executor, {
			groupId: input.groupId,
			id: input.id,
			changes: {
				description: normalized.description,
				amount: normalized.amount,
				occurredAt: new Date(normalized.occurredAt),
				category: normalized.category,
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
		const after = (await getTransaction(executor, input.groupId, input.id))
			.transaction;
		await insertActivity(executor, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: "update",
			entityType: "transaction",
			entityId: input.id,
			summary: after.description,
			before: Object.fromEntries(altered.map((k) => [k, before[k]])),
			after: Object.fromEntries(altered.map((k) => [k, after[k]])),
			createdAt: deps.now(),
		});
		return { transaction: after };
	});
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
		const after = (await getTransaction(executor, input.groupId, input.id))
			.transaction;
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
