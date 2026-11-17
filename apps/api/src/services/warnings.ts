import type {
	CreateTransactionRequest,
	TransactionWarning,
} from "@songphang/contract";
import { type DbExecutor, findFund, listMemberBalances } from "@songphang/db";

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

export async function transactionWarnings(
	executor: DbExecutor,
	input: {
		groupId: string;
		request: CreateTransactionRequest;
		applied: boolean;
	},
): Promise<TransactionWarning[]> {
	const fund = await findFund(executor, input.groupId);
	if (fund === null) return [];
	const deltaCash = fundCashDelta(input.request, fund.id);
	if (deltaCash >= 0) return [];
	const balances = await listMemberBalances(executor, input.groupId);
	const fundBalance =
		balances.find((row) => row.memberId === fund.id)?.balance ?? 0;
	const currentCash = -fundBalance;
	const afterCash = input.applied ? currentCash : currentCash + deltaCash;
	return afterCash < 0 ? ["FUND_OVERDRAWN"] : [];
}
