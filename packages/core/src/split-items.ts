import { allocateByWeights } from "./allocate.ts";
import { parseHundredths } from "./decimal.ts";
import type { Share, SplitResult } from "./split.ts";

export type ItemExtraKind =
	| "tax"
	| "service"
	| "shipping"
	| "discount"
	| "other";

export type ExtrasAllocation = "equal" | "proportional";

export type ItemSplitEntry = {
	name: string;
	amount: number;
	memberIds: readonly string[];
};

export type ItemExtraEntry = {
	kind: ItemExtraKind;
	label: string;
	amount: number;
	ratePercent?: string | undefined;
};

export type ItemsSplitInput = {
	method: "items";
	items: readonly ItemSplitEntry[];
	extras: readonly ItemExtraEntry[];
	extrasAllocation?: ExtrasAllocation | undefined;
};

const RATE_PERCENT_PATTERN = /^\d{1,2}(\.\d{1,2})?$/;

function assertSafeNonnegativeInt(value: number, label: string) {
	if (!Number.isSafeInteger(value) || value < 0) {
		throw new RangeError(`${label} must be a nonnegative safe integer`);
	}
}

export function computePercentExtraAmount(
	baseSubtotal: number,
	ratePercent: string,
): number {
	assertSafeNonnegativeInt(baseSubtotal, "Base subtotal");
	if (!RATE_PERCENT_PATTERN.test(ratePercent)) {
		throw new RangeError("Invalid ratePercent format");
	}
	const rateBps = parseHundredths(ratePercent);
	if (rateBps < 1n || rateBps > 9999n) {
		throw new RangeError("ratePercent must be between 0.01 and 99.99");
	}
	const computed = (BigInt(baseSubtotal) * rateBps + 5000n) / 10000n;
	if (computed > BigInt(Number.MAX_SAFE_INTEGER)) {
		throw new RangeError("Computed extra amount exceeds safe integer");
	}
	return Number(computed);
}

export function sumNetExtras(extras: readonly ItemExtraEntry[]): number {
	let net = 0;
	for (const extra of extras) {
		assertSafeNonnegativeInt(extra.amount, "Extra amount");
		net += extra.kind === "discount" ? -extra.amount : extra.amount;
		if (!Number.isSafeInteger(net)) {
			throw new RangeError("Extras net exceeds safe integer");
		}
	}
	return net;
}

export function validateRatePercentExtras(
	baseSubtotal: number,
	extras: readonly ItemExtraEntry[],
): Extract<SplitResult, { ok: false }> | null {
	for (const extra of extras) {
		assertSafeNonnegativeInt(extra.amount, "Extra amount");
		if (extra.ratePercent !== undefined) {
			const expectedAmount = computePercentExtraAmount(
				baseSubtotal,
				extra.ratePercent,
			);
			if (extra.amount !== expectedAmount) {
				return {
					ok: false,
					code: "SPLIT_TOTAL_MISMATCH",
					expected: expectedAmount,
					actual: extra.amount,
				};
			}
		}
	}
	return null;
}

export function allocateNetExtras(
	baseShares: readonly number[],
	netExtras: number,
	allocation: ExtrasAllocation,
): { ok: true; amounts: number[] } | Extract<SplitResult, { ok: false }> {
	if (baseShares.length === 0) {
		throw new RangeError("Base shares must not be empty");
	}
	let baseTotal = 0;
	for (const share of baseShares) {
		assertSafeNonnegativeInt(share, "Base share");
		baseTotal += share;
		if (!Number.isSafeInteger(baseTotal)) {
			throw new RangeError("Base shares total exceeds safe integer");
		}
	}
	if (!Number.isSafeInteger(netExtras)) {
		throw new RangeError("Net extras must be a safe integer");
	}
	const targetTotal = baseTotal + netExtras;
	if (!Number.isSafeInteger(targetTotal)) {
		throw new RangeError("Target total exceeds safe integer");
	}
	if (netExtras === 0) {
		return { ok: true, amounts: [...baseShares] };
	}

	const allZero = baseShares.every((value) => value === 0);
	if (netExtras > 0) {
		const weights =
			allocation === "equal" || allZero
				? baseShares.map(() => 1n)
				: baseShares.map((value) => BigInt(value));
		const parts = allocateByWeights(netExtras, weights);
		return {
			ok: true,
			amounts: baseShares.map((value, index) => value + (parts[index] ?? 0)),
		};
	}

	const discountToAllocate = -netExtras;
	if (targetTotal < 0 || allZero) {
		return {
			ok: false,
			code: "SPLIT_TOTAL_MISMATCH",
			expected: Math.max(0, targetTotal),
			actual: baseTotal,
		};
	}

	if (allocation === "proportional") {
		const parts = allocateByWeights(
			discountToAllocate,
			baseShares.map((value) => BigInt(value)),
		);
		const amounts: number[] = [];
		for (const [index, baseShare] of baseShares.entries()) {
			const finalAmount = baseShare - (parts[index] ?? 0);
			if (finalAmount < 0) {
				return {
					ok: false,
					code: "SPLIT_TOTAL_MISMATCH",
					expected: targetTotal,
					actual: baseTotal,
				};
			}
			amounts.push(finalAmount);
		}
		return { ok: true, amounts };
	}

	// Water-filling cap ensures equal discount never drives any participant negative.
	const working = [...baseShares];
	let remainingDiscount = discountToAllocate;
	while (remainingDiscount > 0) {
		const weights = working.map((value) => (value > 0 ? 1n : 0n));
		if (weights.every((weight) => weight === 0n)) {
			return {
				ok: false,
				code: "SPLIT_TOTAL_MISMATCH",
				expected: targetTotal,
				actual: baseTotal,
			};
		}
		const cuts = allocateByWeights(remainingDiscount, weights);
		let allFit = true;
		for (let index = 0; index < working.length; index += 1) {
			if ((cuts[index] ?? 0) > (working[index] ?? 0)) {
				allFit = false;
				break;
			}
		}
		if (allFit) {
			for (let index = 0; index < working.length; index += 1) {
				working[index] = (working[index] ?? 0) - (cuts[index] ?? 0);
			}
			remainingDiscount = 0;
			break;
		}
		for (let index = 0; index < working.length; index += 1) {
			const current = working[index] ?? 0;
			const cut = cuts[index] ?? 0;
			if (current > 0 && cut >= current) {
				remainingDiscount -= current;
				working[index] = 0;
			}
		}
	}
	return { ok: true, amounts: working };
}

export function computeItemsNetTotal(
	items: readonly ItemSplitEntry[],
	extras: readonly ItemExtraEntry[],
): number {
	let itemsTotal = 0;
	for (const item of items) {
		assertSafeNonnegativeInt(item.amount, "Item amount");
		itemsTotal += item.amount;
		if (!Number.isSafeInteger(itemsTotal)) {
			throw new RangeError("Items total exceeds safe integer");
		}
	}
	const net = sumNetExtras(extras);
	const actual = itemsTotal + net;
	if (!Number.isSafeInteger(actual)) {
		throw new RangeError("Computed items total exceeds safe integer");
	}
	return actual;
}

export function computeItemShares(
	amount: number,
	split: ItemsSplitInput,
	memberIdsByPosition: readonly string[],
): SplitResult {
	assertSafeNonnegativeInt(amount, "Amount");
	if (amount === 0) {
		throw new RangeError("Amount must be positive");
	}
	if (
		memberIdsByPosition.length === 0 ||
		memberIdsByPosition.some((id) => id.length === 0) ||
		new Set(memberIdsByPosition).size !== memberIdsByPosition.length
	) {
		throw new RangeError("Member IDs must be nonempty and unique");
	}
	if (split.items.length === 0) {
		throw new RangeError("Items split requires at least one item");
	}

	const memberSet = new Set(memberIdsByPosition);
	for (const item of split.items) {
		assertSafeNonnegativeInt(item.amount, "Item amount");
		if (new Set(item.memberIds).size !== item.memberIds.length) {
			throw new RangeError("Item member IDs must be unique");
		}
		if (item.memberIds.some((id) => !memberSet.has(id))) {
			throw new RangeError("Unknown member ID");
		}
	}

	for (const [index, item] of split.items.entries()) {
		if (item.memberIds.length === 0) {
			return { ok: false, code: "ITEM_UNASSIGNED", itemIndex: index };
		}
	}

	const participating = new Set<string>();
	for (const item of split.items) {
		for (const memberId of item.memberIds) {
			participating.add(memberId);
		}
	}
	const ids = memberIdsByPosition.filter((id) => participating.has(id));
	const subtotalMap = new Map(ids.map((id) => [id, 0]));

	let itemsTotal = 0;
	for (const item of split.items) {
		itemsTotal += item.amount;
		if (!Number.isSafeInteger(itemsTotal)) {
			throw new RangeError("Items total exceeds safe integer");
		}
		const itemMembers = memberIdsByPosition.filter((id) =>
			item.memberIds.includes(id),
		);
		const parts = allocateByWeights(
			item.amount,
			itemMembers.map(() => 1n),
		);
		for (const [index, memberId] of itemMembers.entries()) {
			const nextSubtotal =
				(subtotalMap.get(memberId) ?? 0) + (parts[index] ?? 0);
			if (!Number.isSafeInteger(nextSubtotal)) {
				throw new RangeError("Member subtotal exceeds safe integer");
			}
			subtotalMap.set(memberId, nextSubtotal);
		}
	}

	const rateFailure = validateRatePercentExtras(itemsTotal, split.extras);
	if (rateFailure !== null) return rateFailure;

	const net = sumNetExtras(split.extras);
	const actual = itemsTotal + net;
	if (!Number.isSafeInteger(actual)) {
		throw new RangeError("Computed items total exceeds safe integer");
	}
	if (actual !== amount) {
		return {
			ok: false,
			code: "SPLIT_TOTAL_MISMATCH",
			expected: amount,
			actual,
		};
	}

	const subtotals = ids.map((id) => subtotalMap.get(id) ?? 0);
	if (net === 0) {
		return {
			ok: true,
			shares: ids.map((memberId, index) => ({
				memberId,
				amount: subtotals[index] ?? 0,
			})),
		};
	}

	// Preserve Phase 3 proportional default when extrasAllocation is omitted on items.
	const allocation: ExtrasAllocation = split.extrasAllocation ?? "proportional";
	const allocated = allocateNetExtras(subtotals, net, allocation);
	if (!allocated.ok) {
		return {
			ok: false,
			code: "SPLIT_TOTAL_MISMATCH",
			expected: amount,
			actual,
		};
	}

	const shares: Share[] = ids.map((memberId, index) => ({
		memberId,
		amount: allocated.amounts[index] ?? 0,
	}));
	return { ok: true, shares };
}
