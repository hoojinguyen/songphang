export function allocateByWeights(
	total: number,
	weights: readonly bigint[],
): number[] {
	if (
		!Number.isSafeInteger(total) ||
		total < 0 ||
		weights.some((weight) => weight < 0n)
	)
		throw new RangeError("Invalid allocation input");
	const sum = weights.reduce((result, weight) => result + weight, 0n);
	if (sum === 0n) throw new RangeError("Weights must have a positive sum");
	const parts = weights.map((weight, index) => ({
		index,
		quotient: (BigInt(total) * weight) / sum,
		remainder: (BigInt(total) * weight) % sum,
	}));
	const remaining =
		BigInt(total) - parts.reduce((result, part) => result + part.quotient, 0n);
	const ranked = [...parts].sort((a, b) =>
		a.remainder === b.remainder
			? a.index - b.index
			: a.remainder > b.remainder
				? -1
				: 1,
	);
	for (const [index, part] of ranked.entries())
		if (BigInt(index) < remaining) part.quotient += 1n;
	return parts.map((part) => Number(part.quotient));
}
