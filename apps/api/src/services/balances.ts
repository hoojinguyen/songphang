import { BalancesResponse } from "@songphang/contract";
import {
	type LedgerEntry,
	netPairwiseDebts,
	pairDebtsOf,
	suggestMinimizedSettlements,
} from "@songphang/core";
import { findGroup, listLedgerSides, listMemberBalances } from "@songphang/db";
import type { AppDeps } from "../app.js";
import { AppError } from "../errors.js";
export async function getBalances(deps: AppDeps, groupId: string) {
	const group = await findGroup(deps.db, groupId);
	if (group === null)
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	const balances = await listMemberBalances(deps.db, groupId);
	const sides = group.minimizeDebts
		? null
		: await listLedgerSides(deps.db, groupId);
	const debts =
		sides === null
			? []
			: [...new Set(sides.payers.map((p) => p.transactionId))].flatMap((id) => {
					const payers = sides.payers.filter((p) => p.transactionId === id);
					const type = payers[0]?.type;
					if (type !== "expense" && type !== "income" && type !== "transfer")
						throw new Error("Invalid ledger type");
					const entry: LedgerEntry = {
						type,
						payers,
						shares: sides.shares.filter((s) => s.transactionId === id),
					};
					return pairDebtsOf(entry);
				});
	const transfers = group.minimizeDebts
		? suggestMinimizedSettlements(balances)
		: netPairwiseDebts(
				debts,
				balances.map((member) => member.memberId),
			);
	return BalancesResponse.parse({
		currency: group.currency,
		minimized: group.minimizeDebts,
		balances,
		transfers,
	});
}
