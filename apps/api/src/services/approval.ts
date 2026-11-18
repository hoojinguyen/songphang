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
			...(trimmedNote ? { after: { note: trimmedNote } } : {}),
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
			});
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
