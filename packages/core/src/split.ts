export type Share = { memberId: string; amount: number };

export function splitEqually(
	amount: number,
	memberIdsByPosition: readonly string[],
): Share[] {
	if (!Number.isSafeInteger(amount) || amount < 1) {
		throw new RangeError("Amount must be a positive safe integer");
	}
	if (
		memberIdsByPosition.length === 0 ||
		memberIdsByPosition.some((id) => id.length === 0) ||
		new Set(memberIdsByPosition).size !== memberIdsByPosition.length
	) {
		throw new RangeError("Member IDs must be nonempty and unique");
	}
	const count = BigInt(memberIdsByPosition.length);
	const quotient = BigInt(amount) / count;
	const remainder = BigInt(amount) % count;
	return memberIdsByPosition.map((memberId, position) => ({
		memberId,
		amount: Number(quotient + (BigInt(position) < remainder ? 1n : 0n)),
	}));
}
