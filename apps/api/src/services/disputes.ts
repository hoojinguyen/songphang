import { z } from "@hono/zod-openapi";
import {
	DisputeResponse,
	type OpenDisputeRequest,
	TransactionDisputeDto,
	type UserDto,
} from "@songphang/contract";
import {
	type DisputeRow,
	findGroup,
	findGroupOwnerUserId,
	findOpenDisputeForTransaction,
	findTransactionRow,
	findUserById,
	insertActivity,
	insertDisputeRow,
	lockGroup,
	resolveDisputeRow,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { getGroupAccess } from "../auth/group-access.js";
import { AppError } from "../errors.js";
import { notify } from "./notify.js";

function toDisputeDto(
	row: DisputeRow,
	viewerUserId: string | null,
): TransactionDisputeDto {
	return TransactionDisputeDto.parse({
		id: row.id,
		reason: row.reason,
		openedByName: row.openedByName,
		openedAt: row.openedAt.toISOString(),
		mine: viewerUserId !== null && row.openedBy === viewerUserId,
	});
}

export async function openDispute(
	deps: AppDeps,
	input: {
		groupId: string;
		transactionId: string;
		user: UserDto;
		request: OpenDisputeRequest;
	},
): Promise<DisputeResponse> {
	if (!z.uuid().safeParse(input.transactionId).success)
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	const now = deps.now();
	const result = await deps.db.transaction(async (executor) => {
		await lockGroup(executor, input.groupId);
		await getGroupAccess(executor, {
			groupId: input.groupId,
			userId: input.user.id,
			minimumRole: "viewer",
		});
		const transaction = await findTransactionRow(
			executor,
			input.groupId,
			input.transactionId,
		);
		if (transaction === null || transaction.deletedAt !== null)
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		const existing = await findOpenDisputeForTransaction(
			executor,
			input.groupId,
			input.transactionId,
		);
		if (existing !== null)
			throw new AppError(
				409,
				"DISPUTE_ALREADY_OPEN",
				"A dispute is already open on this transaction",
			);
		const row = await insertDisputeRow(executor, {
			groupId: input.groupId,
			transactionId: input.transactionId,
			reason: input.request.reason,
			openedBy: input.user.id,
			openedByName: input.user.name,
			openedAt: now,
		});
		await insertActivity(executor, {
			groupId: input.groupId,
			actorUserId: input.user.id,
			action: "dispute_open",
			entityType: "transaction",
			entityId: input.transactionId,
			summary: transaction.description,
			after: { reason: input.request.reason },
			createdAt: now,
		});
		const [group, ownerUserId] = await Promise.all([
			findGroup(executor, input.groupId),
			findGroupOwnerUserId(executor, input.groupId),
		]);
		await notify(executor, {
			groupId: input.groupId,
			actorUserId: input.user.id,
			kind: "dispute_opened",
			payload: {
				kind: "dispute_opened",
				actorName: input.user.name,
				groupName: group?.name ?? "",
				transactionId: transaction.id,
				description: transaction.description,
				reason: input.request.reason,
			},
			toUserIds: [
				...(transaction.createdBy ? [transaction.createdBy.id] : []),
				...(ownerUserId ? [ownerUserId] : []),
				input.user.id,
			],
			now,
			enqueue: deps.enqueue,
		});
		return DisputeResponse.parse({
			dispute: toDisputeDto(row, input.user.id),
		});
	});
	deps.events.publishChanged(input.groupId, ["transactions", "activity"]);
	return result;
}

export async function resolveDispute(
	deps: AppDeps,
	input: {
		groupId: string;
		transactionId: string;
		userId: string;
	},
): Promise<DisputeResponse> {
	if (!z.uuid().safeParse(input.transactionId).success)
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	const now = deps.now();
	const result = await deps.db.transaction(async (executor) => {
		await lockGroup(executor, input.groupId);
		const access = await getGroupAccess(executor, {
			groupId: input.groupId,
			userId: input.userId,
			minimumRole: "viewer",
		});
		const transaction = await findTransactionRow(
			executor,
			input.groupId,
			input.transactionId,
		);
		if (transaction === null || transaction.deletedAt !== null)
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		const open = await findOpenDisputeForTransaction(
			executor,
			input.groupId,
			input.transactionId,
		);
		if (open === null)
			throw new AppError(
				409,
				"DISPUTE_NOT_OPEN",
				"No open dispute on this transaction",
			);
		if (open.openedBy !== input.userId && access.role !== "owner")
			throw new AppError(403, "FORBIDDEN", "Insufficient group role");
		await resolveDisputeRow(executor, {
			groupId: input.groupId,
			disputeId: open.id,
			resolvedBy: input.userId,
			resolvedAt: now,
		});
		await insertActivity(executor, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: "dispute_resolve",
			entityType: "transaction",
			entityId: input.transactionId,
			summary: transaction.description,
			before: { reason: open.reason },
			createdAt: now,
		});
		const [group, ownerUserId, actor] = await Promise.all([
			findGroup(executor, input.groupId),
			findGroupOwnerUserId(executor, input.groupId),
			findUserById(executor, input.userId),
		]);
		await notify(executor, {
			groupId: input.groupId,
			actorUserId: input.userId,
			kind: "dispute_resolved",
			payload: {
				kind: "dispute_resolved",
				actorName: actor?.name ?? "",
				groupName: group?.name ?? "",
				transactionId: transaction.id,
				description: transaction.description,
			},
			toUserIds: [
				...(transaction.createdBy ? [transaction.createdBy.id] : []),
				...(ownerUserId ? [ownerUserId] : []),
				...(open.openedBy ? [open.openedBy] : []),
			],
			now,
			enqueue: deps.enqueue,
		});
		return DisputeResponse.parse({ dispute: null });
	});
	deps.events.publishChanged(input.groupId, ["transactions", "activity"]);
	return result;
}
