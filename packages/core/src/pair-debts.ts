import { allocateByWeights } from "./allocate.ts";
import type { PairDebt } from "./settlements.ts";
import type { Share } from "./split.ts";
export type LedgerEntry = {
	type: "expense" | "transfer" | "income";
	payers: readonly Share[];
	shares: readonly Share[];
};
export function pairDebtsOf(entry: LedgerEntry): PairDebt[] {
	for (const share of [...entry.payers, ...entry.shares])
		if (!Number.isSafeInteger(share.amount) || share.amount < 0)
			throw new RangeError("Invalid ledger amount");
	const payerTotal = entry.payers.reduce(
		(sum, payer) => sum + BigInt(payer.amount),
		0n,
	);
	const shareTotal = entry.shares.reduce(
		(sum, share) => sum + BigInt(share.amount),
		0n,
	);
	if (payerTotal !== shareTotal)
		throw new RangeError("Ledger totals must match");
	const capacities = entry.payers.map((payer) => BigInt(payer.amount));
	const debts: PairDebt[] = [];
	for (const share of entry.shares) {
		if (share.amount === 0) continue;
		const parts = allocateByWeights(share.amount, capacities);
		for (const [index, payer] of entry.payers.entries()) {
			const amount = parts[index] ?? 0;
			if (amount === 0) continue;
			capacities[index] = (capacities[index] ?? 0n) - BigInt(amount);
			debts.push({
				debtorMemberId:
					entry.type === "income" ? payer.memberId : share.memberId,
				creditorMemberId:
					entry.type === "income" ? share.memberId : payer.memberId,
				amount,
			});
		}
	}
	return debts;
}
