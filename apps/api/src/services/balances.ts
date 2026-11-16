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
	return deps.db.transaction(
		async (executor) => {
			const group = await findGroup(executor, groupId);
			if (group === null)
				throw new AppError(404, "NOT_FOUND", "Resource not found");
			const balances = await listMemberBalances(executor, groupId);
			if (balances.length === 0)
				return BalancesResponse.parse({
					currency: group.currency,
					minimized: group.minimizeDebts,
					balances: [],
					transfers: [],
				});
			const sides = group.minimizeDebts
				? null
				: await listLedgerSides(executor, groupId);
			const debts = sides === null ? [] : ledgerDebts(sides);
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
		},
		{ isolationLevel: "repeatable read", accessMode: "read only" },
	);
}

function ledgerDebts(sides: Awaited<ReturnType<typeof listLedgerSides>>) {
	return [...new Set(sides.payers.map((payer) => payer.transactionId))].flatMap(
		(id) => {
			const payers = sides.payers.filter((payer) => payer.transactionId === id);
			const type = payers[0]?.type;
			if (type !== "expense" && type !== "income" && type !== "transfer")
				throw new Error("Invalid ledger type");
			const entry: LedgerEntry = {
				type,
				payers,
				shares: sides.shares.filter((share) => share.transactionId === id),
			};
			return pairDebtsOf(entry);
		},
	);
}
