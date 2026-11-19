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

export type ReplacedTransaction = {
	type: "expense" | "income" | "transfer";
	amount: number;
	occurredAt: Date;
	payers: Array<{ memberId: string; amount: number }>;
	counted?: boolean;
};

function splitFundCashDelta(
	type: "expense" | "income",
	payers: Array<{ memberId: string; amount: number }>,
	fundId: string,
): number {
	const paid = payers.find((payer) => payer.memberId === fundId)?.amount ?? 0;
	return type === "income" ? paid : -paid;
}

function fundCashDelta(
	request: CreateTransactionRequest,
	fundId: string,
): number {
	if (request.type === "transfer") {
		const inAmount = request.toMemberId === fundId ? request.amount : 0;
		const outAmount = request.fromMemberId === fundId ? request.amount : 0;
		return inAmount - outAmount;
	}
	return splitFundCashDelta(request.type, request.payers, fundId);
}

function replacedFundCashDelta(
	replacing: ReplacedTransaction,
	fundId: string,
): number {
	if (replacing.type === "transfer") return 0;
	return splitFundCashDelta(replacing.type, replacing.payers, fundId);
}

function inPeriod(
	date: Date,
	periodStart: string | null,
	periodEnd: string | null,
): boolean {
	if (periodStart === null || periodEnd === null) return true;
	const local = toVietnamDate(date);
	return local >= periodStart && local <= periodEnd;
}

async function fundOverdrawWarning(
	executor: DbExecutor,
	input: {
		groupId: string;
		request: CreateTransactionRequest;
		applied: boolean;
		replacing?: ReplacedTransaction;
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
	const oldDelta =
		input.replacing && input.replacing.counted !== false
			? replacedFundCashDelta(input.replacing, fund.id)
			: 0;
	const afterCash = input.applied
		? currentCash
		: currentCash - oldDelta + deltaCash;
	return afterCash < 0 ? "FUND_OVERDRAWN" : null;
}

async function budgetLimitWarning(
	executor: DbExecutor,
	input: {
		groupId: string;
		request: CreateTransactionRequest;
		applied: boolean;
		now: Date;
		replacing?: ReplacedTransaction;
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
	if (!inPeriod(new Date(input.request.occurredAt), periodStart, periodEnd))
		return null;
	const spentNow = await sumSpent(executor, input.groupId, utcRange);
	const signedAmount =
		input.request.type === "income"
			? -input.request.amount
			: input.request.amount;
	const oldSigned =
		input.replacing &&
		input.replacing.counted !== false &&
		input.replacing.type !== "transfer" &&
		inPeriod(input.replacing.occurredAt, periodStart, periodEnd)
			? input.replacing.type === "income"
				? -input.replacing.amount
				: input.replacing.amount
			: 0;
	const afterSpent = input.applied
		? spentNow
		: spentNow - oldSigned + signedAmount;
	const beforeSpent = input.applied
		? spentNow - signedAmount + oldSigned
		: spentNow;
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
		replacing?: ReplacedTransaction;
		counted?: boolean;
	},
): Promise<TransactionWarning[]> {
	if (input.counted === false) return [];
	const [fundWarning, budgetWarning] = await Promise.all([
		fundOverdrawWarning(executor, input),
		budgetLimitWarning(executor, input),
	]);
	return [
		...(fundWarning ? [fundWarning] : []),
		...(budgetWarning ? [budgetWarning] : []),
	];
}
