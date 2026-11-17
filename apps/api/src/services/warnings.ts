import type {
	CreateTransactionRequest,
	TransactionWarning,
} from "@songphang/contract";
import { budgetState, toVietnamDate } from "@songphang/core";
import {
	type DbExecutor,
	findBudget,
	findFund,
	listMemberBalances,
	sumSpent,
} from "@songphang/db";
import { budgetRangeFor } from "./budget.js";

function fundCashDelta(
	request: CreateTransactionRequest,
	fundId: string,
): number {
	if (request.type === "transfer") {
		const inAmount = request.toMemberId === fundId ? request.amount : 0;
		const outAmount = request.fromMemberId === fundId ? request.amount : 0;
		return inAmount - outAmount;
	}
	const paid =
		request.payers.find((payer) => payer.memberId === fundId)?.amount ?? 0;
	return request.type === "income" ? paid : -paid;
}

async function fundOverdrawWarning(
	executor: DbExecutor,
	input: {
		groupId: string;
		request: CreateTransactionRequest;
		applied: boolean;
	},
): Promise<TransactionWarning | null> {
	const fund = await findFund(executor, input.groupId);
	if (fund === null) return null;
	const deltaCash = fundCashDelta(input.request, fund.id);
	if (deltaCash >= 0) return null;
	const balances = await listMemberBalances(executor, input.groupId);
	const fundBalance =
		balances.find((row) => row.memberId === fund.id)?.balance ?? 0;
	const currentCash = -fundBalance;
	const afterCash = input.applied ? currentCash : currentCash + deltaCash;
	return afterCash < 0 ? "FUND_OVERDRAWN" : null;
}

async function budgetLimitWarning(
	executor: DbExecutor,
	input: {
		groupId: string;
		request: CreateTransactionRequest;
		applied: boolean;
		now: Date;
	},
): Promise<TransactionWarning | null> {
	if (input.request.type === "transfer") return null;
	const row = await findBudget(executor, input.groupId);
	if (row === null) return null;
	const period = row.period === "total" ? "total" : "month";
	const { periodStart, periodEnd, utcRange } = budgetRangeFor(
		period,
		input.now,
	);
	if (periodStart !== null && periodEnd !== null) {
		const txDate = toVietnamDate(new Date(input.request.occurredAt));
		if (txDate < periodStart || txDate > periodEnd) return null;
	}
	const spentNow = await sumSpent(executor, input.groupId, utcRange);
	const signedAmount =
		input.request.type === "income"
			? -input.request.amount
			: input.request.amount;
	const afterSpent = input.applied ? spentNow : spentNow + signedAmount;
	const beforeSpent = input.applied ? spentNow - signedAmount : spentNow;
	const beforeState = budgetState(beforeSpent, row.amount);
	const afterState = budgetState(afterSpent, row.amount);
	if (afterState === "over" && beforeState !== "over") return "BUDGET_OVER";
	if (afterState === "near" && beforeState === "ok") return "BUDGET_NEAR";
	return null;
}

export async function transactionWarnings(
	executor: DbExecutor,
	input: {
		groupId: string;
		request: CreateTransactionRequest;
		applied: boolean;
		now: Date;
	},
): Promise<TransactionWarning[]> {
	const [fundWarning, budgetWarning] = await Promise.all([
		fundOverdrawWarning(executor, input),
		budgetLimitWarning(executor, input),
	]);
	return [
		...(fundWarning ? [fundWarning] : []),
		...(budgetWarning ? [budgetWarning] : []),
	];
}
