import { z } from "@hono/zod-openapi";
import {
	SplitTransactionRequest,
	TransactionResponse,
} from "@songphang/contract";
import {
	findGroup,
	findTransactionRow,
	findUserById,
	insertActivity,
	lockGroup,
	lockTransaction,
	updateTransactionRow,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { getGroupAccess } from "../auth/group-access.js";
import { AppError } from "../errors.js";
import { notify, notifyBudgetWarnings } from "./notify.js";
import { mapTransactions } from "./transactions.js";
import { transactionWarnings } from "./warnings.js";

export async function decideTransactionApproval(
	deps: AppDeps,
	input: {
		groupId: string;
		id: string;
		userId: string;
		decision: "approved" | "rejected";
		note?: string | undefined;
	},
) {
	const now = deps.now();
	if (!z.uuid().safeParse(input.id).success) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	const trimmedNote = input.note?.trim() ? input.note.trim() : null;
	const result = await deps.db.transaction(async (executor) => {
		await lockGroup(executor, input.groupId);
		await getGroupAccess(executor, {
			groupId: input.groupId,
			userId: input.userId,
			minimumRole: "owner",
		});
		const locked = await lockTransaction(executor, input.groupId, input.id);
		const row = locked
			? await findTransactionRow(executor, input.groupId, input.id)
			: null;
		if (row === null || row.deletedAt !== null) {
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		}
		if (row.approvalStatus !== "pending") {
			throw new AppError(
				409,
				"APPROVAL_NOT_PENDING",
				"Transaction is not pending approval",
			);
		}
		await updateTransactionRow(executor, {
			groupId: input.groupId,
			id: input.id,
			changes: {
				approvalStatus: input.decision,
				approvalDecidedBy: input.userId,
				approvalDecidedAt: now,
				approvalNote: trimmedNote,
				version: row.version + 1,
				updatedBy: input.userId,
				updatedAt: now,
			},
		});
		const updatedRow = await findTransactionRow(
			executor,
			input.groupId,
			input.id,
		);
		if (updatedRow === null) {
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		}
		const [[transaction], group, actor] = await Promise.all([
			mapTransactions(executor, input.groupId, [updatedRow], input.userId),
			findGroup(executor, input.groupId),
			findUserById(executor, input.userId),
		]);
		if (transaction === undefined || group === null) {
			throw new Error("Approved transaction not found");
		}
		const actorName = actor?.name ?? "";
		await insertActivity(executor, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: input.decision === "approved" ? "approve" : "reject",
			entityType: "transaction",
			entityId: input.id,
			summary: transaction.description,
			after: {
				amount: transaction.amount,
				...(trimmedNote ? { note: trimmedNote } : {}),
			},
			createdAt: now,
		});
		if (row.createdBy !== null) {
			await notify(executor, {
				groupId: input.groupId,
				actorUserId: input.userId,
				kind: "approval_decided",
				payload: {
					kind: "approval_decided",
					actorName,
					groupName: group.name,
					transactionId: input.id,
					description: transaction.description,
					decision: input.decision,
				},
				toUserIds: [row.createdBy.id],
				now,
				enqueue: deps.enqueue,
				pushEnabled: Boolean(deps.config.pushProvider),
			});
		}
		if (input.decision === "approved" && transaction.type === "expense") {
			const creatorName = row.createdBy?.name ?? actorName;
			const shareByMember = new Map(
				transaction.shares.map((s) => [s.memberId, s.amount]),
			);
			const participantMemberIds = [
				...new Set([
					...transaction.payers.map((p) => p.memberId),
					...transaction.shares.map((s) => s.memberId),
				]),
			];
			for (const memberId of participantMemberIds) {
				const share = shareByMember.get(memberId) ?? 0;
				await notify(executor, {
					groupId: input.groupId,
					actorUserId: row.createdBy?.id ?? input.userId,
					kind: "expense_added",
					payload: {
						kind: "expense_added",
						actorName: creatorName,
						groupName: group.name,
						transactionId: input.id,
						description: transaction.description,
						share,
					},
					toMemberIds: [memberId],
					now,
					enqueue: deps.enqueue,
					pushEnabled: Boolean(deps.config.pushProvider),
				});
			}
		}
		let warnings: Awaited<ReturnType<typeof transactionWarnings>> = [];
		if (input.decision === "approved" && transaction.type !== "transfer") {
			const parsedRequest = SplitTransactionRequest.safeParse({
				type: transaction.type,
				description: transaction.description,
				amount: transaction.amount,
				occurredAt: transaction.occurredAt,
				category: transaction.category,
				categoryId: transaction.categoryId,
				payers: transaction.payers,
				split: transaction.split,
			});
			if (parsedRequest.success) {
				warnings = await transactionWarnings(executor, {
					groupId: input.groupId,
					request: parsedRequest.data,
					applied: true,
					now,
				});
				await notifyBudgetWarnings(executor, {
					groupId: input.groupId,
					actorUserId: input.userId,
					actorName,
					groupName: group.name,
					warnings,
					now,
				});
			}
		}
		return { transaction, warnings };
	});
	deps.events.publishChanged(input.groupId, [
		"transactions",
		"balances",
		"activity",
		"budget",
	]);
	return TransactionResponse.parse(result);
}
