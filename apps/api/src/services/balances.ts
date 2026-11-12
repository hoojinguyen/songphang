import { BalancesResponse } from "@songphang/contract";
import { netPairwiseDebts, suggestMinimizedSettlements } from "@songphang/core";
import { findGroup, listMemberBalances, listPairDebts } from "@songphang/db";
import type { AppDeps } from "../app.js";
import { AppError } from "../errors.js";
export async function getBalances(deps: AppDeps, groupId: string) {
	const group = await findGroup(deps.db, groupId);
	if (group === null)
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	const balances = await listMemberBalances(deps.db, groupId);
	const transfers = group.minimizeDebts
		? suggestMinimizedSettlements(balances)
		: netPairwiseDebts(
				await listPairDebts(deps.db, groupId),
				balances.map((member) => member.memberId),
			);
	return BalancesResponse.parse({
		currency: group.currency,
		minimized: group.minimizeDebts,
		balances,
		transfers,
	});
}
