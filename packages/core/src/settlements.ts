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
export type HouseholdGroup = {
	id: string;
	name: string;
	representativeMemberId: string;
	memberIds: readonly string[];
};
export type HouseholdBalanceSummary = {
	id: string;
	name: string;
	representativeMemberId: string;
	memberIds: string[];
	netBalance: number;
	memberBalances: MemberBalance[];
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

function validateZeroSumBalances(
	balancesByPosition: readonly MemberBalance[],
): void {
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
}

export function suggestMinimizedSettlements(
	balancesByPosition: readonly MemberBalance[],
): Settlement[] {
	validateZeroSumBalances(balancesByPosition);
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

export function consolidateHouseholdBalances(
	balancesByPosition: readonly MemberBalance[],
	households: readonly HouseholdGroup[],
): {
	consolidated: MemberBalance[];
	summaries: HouseholdBalanceSummary[];
} {
	validateZeroSumBalances(balancesByPosition);
	const balanceByMember = new Map(
		balancesByPosition.map((entry) => [entry.memberId, entry.balance]),
	);
	const positionByMember = new Map(
		balancesByPosition.map((entry, index) => [entry.memberId, index]),
	);
	const assignedMembers = new Set<string>();
	const representativeNetByMember = new Map<string, number>();
	const summaries: HouseholdBalanceSummary[] = [];

	for (const household of households) {
		if (
			household.memberIds.length < 2 ||
			new Set(household.memberIds).size !== household.memberIds.length
		) {
			throw new RangeError("Household must have at least two distinct members");
		}
		if (!household.memberIds.includes(household.representativeMemberId)) {
			throw new RangeError(
				"Household representative must belong to the household",
			);
		}
		for (const memberId of household.memberIds) {
			if (!balanceByMember.has(memberId)) {
				throw new RangeError("Household contains unknown member");
			}
			if (assignedMembers.has(memberId)) {
				throw new RangeError("Member belongs to multiple households");
			}
			assignedMembers.add(memberId);
		}

		const orderedMemberIds = [...household.memberIds].sort(
			(a, b) => (positionByMember.get(a) ?? 0) - (positionByMember.get(b) ?? 0),
		);
		const memberBalances = orderedMemberIds.map((memberId) => ({
			memberId,
			balance: balanceByMember.get(memberId) ?? 0,
		}));
		const netBig = memberBalances.reduce(
			(sum, entry) => sum + BigInt(entry.balance),
			0n,
		);
		if (
			netBig < BigInt(Number.MIN_SAFE_INTEGER) ||
			netBig > BigInt(Number.MAX_SAFE_INTEGER)
		) {
			throw new RangeError("Household net balance exceeds safe integer range");
		}
		const netBalance = Number(netBig);
		representativeNetByMember.set(household.representativeMemberId, netBalance);
		summaries.push({
			id: household.id,
			name: household.name,
			representativeMemberId: household.representativeMemberId,
			memberIds: orderedMemberIds,
			netBalance,
			memberBalances,
		});
	}

	const consolidated = balancesByPosition.map((entry) => {
		if (!assignedMembers.has(entry.memberId)) {
			return { memberId: entry.memberId, balance: entry.balance };
		}
		const repNet = representativeNetByMember.get(entry.memberId);
		return {
			memberId: entry.memberId,
			balance: repNet !== undefined ? repNet : 0,
		};
	});

	return { consolidated, summaries };
}

export function suggestHouseholdSettlements(input: {
	balancesByPosition: readonly MemberBalance[];
	minimizeDebts: boolean;
	pairDebts?: readonly PairDebt[];
	households: readonly HouseholdGroup[];
}): {
	transfers: Settlement[];
	summaries: HouseholdBalanceSummary[];
} {
	if (input.balancesByPosition.length === 0) {
		return { transfers: [], summaries: [] };
	}
	const { consolidated, summaries } = consolidateHouseholdBalances(
		input.balancesByPosition,
		input.households,
	);
	if (input.minimizeDebts) {
		return {
			transfers: suggestMinimizedSettlements(consolidated),
			summaries,
		};
	}

	const representativeOf = new Map<string, string>();
	for (const household of input.households) {
		for (const memberId of household.memberIds) {
			representativeOf.set(memberId, household.representativeMemberId);
		}
	}
	const mappedDebts: PairDebt[] = (input.pairDebts ?? []).map((debt) => ({
		debtorMemberId:
			representativeOf.get(debt.debtorMemberId) ?? debt.debtorMemberId,
		creditorMemberId:
			representativeOf.get(debt.creditorMemberId) ?? debt.creditorMemberId,
		amount: debt.amount,
	}));

	return {
		transfers: netPairwiseDebts(
			mappedDebts,
			input.balancesByPosition.map((entry) => entry.memberId),
		),
		summaries,
	};
}
