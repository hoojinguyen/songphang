import { allocateByWeights } from "./allocate.ts";
import type { Share, SplitResult } from "./split.ts";

export type ItemExtraKind = "tax" | "service" | "discount" | "other";

export type ItemSplitEntry = {
	name: string;
	amount: number;
	memberIds: readonly string[];
};

export type ItemExtraEntry = {
	kind: ItemExtraKind;
	label: string;
	amount: number;
};

export type ItemsSplitInput = {
	method: "items";
	items: readonly ItemSplitEntry[];
	extras: readonly ItemExtraEntry[];
};

function assertSafeNonnegativeInt(value: number, label: string) {
	if (!Number.isSafeInteger(value) || value < 0) {
		throw new RangeError(`${label} must be a nonnegative safe integer`);
	}
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
	let net = 0;
	for (const extra of extras) {
		assertSafeNonnegativeInt(extra.amount, "Extra amount");
		net += extra.kind === "discount" ? -extra.amount : extra.amount;
		if (!Number.isSafeInteger(net)) {
			throw new RangeError("Extras net exceeds safe integer");
		}
	}
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

	let net = 0;
	for (const extra of split.extras) {
		assertSafeNonnegativeInt(extra.amount, "Extra amount");
		net += extra.kind === "discount" ? -extra.amount : extra.amount;
		if (!Number.isSafeInteger(net)) {
			throw new RangeError("Extras net exceeds safe integer");
		}
	}

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
	const allZero = subtotals.every((value) => value === 0);

	if (net === 0) {
		return {
			ok: true,
			shares: ids.map((memberId, index) => ({
				memberId,
				amount: subtotals[index] ?? 0,
			})),
		};
	}

	if (net > 0) {
		const weights = allZero
			? ids.map(() => 1n)
			: subtotals.map((value) => BigInt(value));
		const parts = allocateByWeights(net, weights);
		return {
			ok: true,
			shares: ids.map((memberId, index) => ({
				memberId,
				amount: (subtotals[index] ?? 0) + (parts[index] ?? 0),
			})),
		};
	}

	if (allZero) {
		return {
			ok: false,
			code: "SPLIT_TOTAL_MISMATCH",
			expected: amount,
			actual,
		};
	}

	const parts = allocateByWeights(
		-net,
		subtotals.map((value) => BigInt(value)),
	);
	const shares: Share[] = [];
	for (const [index, memberId] of ids.entries()) {
		const finalAmount = (subtotals[index] ?? 0) - (parts[index] ?? 0);
		if (finalAmount < 0) {
			return {
				ok: false,
				code: "SPLIT_TOTAL_MISMATCH",
				expected: amount,
				actual,
			};
		}
		shares.push({ memberId, amount: finalAmount });
	}
	return { ok: true, shares };
}
