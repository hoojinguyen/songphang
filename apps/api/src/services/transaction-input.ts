import type { CreateTransactionRequest, SplitInput } from "@songphang/contract";
import { computeShares } from "@songphang/core";
import { type DbExecutor, listGroupMembers } from "@songphang/db";
import { vi } from "../../../web/src/messages/vi.ts";
import { AppError } from "../errors.js";
export function normalizeTransaction(request: CreateTransactionRequest) {
	if (request.type !== "transfer") return request;
	const split: SplitInput = {
		method: "exact",
		members: [request.toMemberId],
		entries: [{ memberId: request.toMemberId, amount: request.amount }],
		remainder: "none",
	};
	return {
		type: request.type,
		description:
			request.description ?? vi.expenseForm.defaultTransferDescription,
		amount: request.amount,
		occurredAt: request.occurredAt,
		category: null,
		categoryId: null,
		payers: [{ memberId: request.fromMemberId, amount: request.amount }],
		split,
	};
}
export async function calculateShares(
	executor: DbExecutor,
	groupId: string,
	input: CreateTransactionRequest,
) {
	const request = normalizeTransaction(input);
	if (input.type === "income" && request.split.method === "items") {
		throw new AppError(
			400,
			"VALIDATION_FAILED",
			"Income transactions cannot split by items",
		);
	}
	const members = await listGroupMembers(executor, groupId);
	const splitIds =
		request.split.method === "equal" || request.split.method === "exact"
			? request.split.members
			: request.split.method === "items"
				? [...new Set(request.split.items.flatMap((item) => item.memberIds))]
				: request.split.entries.map((e) => e.memberId);
	const allIds = [...request.payers.map((p) => p.memberId), ...splitIds];
	if (allIds.some((id) => !members.some((m) => m.id === id)))
		throw new AppError(
			400,
			"MEMBER_NOT_IN_GROUP",
			"Member does not belong to group",
		);
	if (
		input.type !== "transfer" &&
		splitIds.some((id) => members.find((m) => m.id === id)?.kind === "fund")
	)
		throw new AppError(
			422,
			"FUND_CANNOT_SHARE",
			"Fund member cannot bear a share",
		);
	const paid = request.payers.reduce((sum, payer) => sum + payer.amount, 0);
	if (paid !== request.amount)
		throw new AppError(
			400,
			"PAYER_TOTAL_MISMATCH",
			"Payer total differs from amount",
			{ expected: request.amount, actual: paid },
		);
	const result = computeShares(
		request.amount,
		request.split,
		members.map((m) => m.id),
	);
	if (!result.ok) {
		if (result.code === "ITEM_UNASSIGNED") {
			throw new AppError(
				400,
				"ITEM_UNASSIGNED",
				"Item has no assigned members",
				{
					itemIndex: result.itemIndex,
				},
			);
		}
		throw new AppError(400, result.code, "Split total differs from amount", {
			expected: result.expected,
			actual: result.actual,
		});
	}
	return result.shares;
}
