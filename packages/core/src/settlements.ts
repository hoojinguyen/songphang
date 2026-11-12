export type MemberBalance = { memberId: string; balance: number };
export type Settlement = {
	fromMemberId: string;
	toMemberId: string;
	amount: number;
};
export type PairDebt = {
	debtorMemberId: string;
	creditorMemberId: string;
	amount: number;
};

function validateMemberIds(ids: readonly string[]): void {
	if (
		ids.length === 0 ||
		ids.some((id) => id.length === 0) ||
		new Set(ids).size !== ids.length
	) {
		throw new RangeError("Member IDs must be nonempty and unique");
	}
}

export function suggestMinimizedSettlements(
	balancesByPosition: readonly MemberBalance[],
): Settlement[] {
	validateMemberIds(balancesByPosition.map(({ memberId }) => memberId));
	if (
		balancesByPosition.some(({ balance }) => !Number.isSafeInteger(balance))
	) {
		throw new RangeError("Balances must be safe integers");
	}
	if (
		balancesByPosition.reduce(
			(sum, { balance }) => sum + BigInt(balance),
			0n,
		) !== 0n
	) {
		throw new RangeError("Balances must sum to zero");
	}
	const remaining = balancesByPosition.map((balance) => ({ ...balance }));
	const settlements: Settlement[] = [];
	while (true) {
		const debtor = remaining.reduce((lowest, current) =>
			current.balance < lowest.balance ? current : lowest,
		);
		const creditor = remaining.reduce((highest, current) =>
			current.balance > highest.balance ? current : highest,
		);
		if (debtor.balance === 0) return settlements;
		const amount = Math.min(-debtor.balance, creditor.balance);
		settlements.push({
			fromMemberId: debtor.memberId,
			toMemberId: creditor.memberId,
			amount,
		});
		debtor.balance += amount;
		creditor.balance -= amount;
	}
}

function accumulatePairDebts(
	debts: readonly PairDebt[],
	memberIds: readonly string[],
) {
	const positions = new Map(memberIds.map((id, position) => [id, position]));
	const totals = new Map<string, bigint>();
	for (const debt of debts) {
		const debtor = positions.get(debt.debtorMemberId);
		const creditor = positions.get(debt.creditorMemberId);
		if (
			debtor === undefined ||
			creditor === undefined ||
			!Number.isSafeInteger(debt.amount) ||
			debt.amount < 1
		) {
			throw new RangeError(
				"Debt must have known members and a positive safe integer amount",
			);
		}
		if (debtor === creditor) continue;
		const key = `${Math.min(debtor, creditor)}:${Math.max(debtor, creditor)}`;
		const signed = BigInt(debt.amount) * (debtor < creditor ? 1n : -1n);
		totals.set(key, (totals.get(key) ?? 0n) + signed);
	}
	return totals;
}

export function netPairwiseDebts(
	debts: readonly PairDebt[],
	memberIdsByPosition: readonly string[],
): Settlement[] {
	validateMemberIds(memberIdsByPosition);
	const totals = accumulatePairDebts(debts, memberIdsByPosition);
	const settlements: Settlement[] = [];
	for (const [debtorPosition, fromMemberId] of memberIdsByPosition.entries()) {
		for (const [
			creditorPosition,
			toMemberId,
		] of memberIdsByPosition.entries()) {
			if (debtorPosition === creditorPosition) continue;
			const key = `${Math.min(debtorPosition, creditorPosition)}:${Math.max(debtorPosition, creditorPosition)}`;
			const net =
				(totals.get(key) ?? 0n) *
				(debtorPosition < creditorPosition ? 1n : -1n);
			if (net <= 0n) continue;
			if (net > BigInt(Number.MAX_SAFE_INTEGER))
				throw new RangeError("Net debt exceeds safe integer range");
			settlements.push({ fromMemberId, toMemberId, amount: Number(net) });
		}
	}
	return settlements;
}
