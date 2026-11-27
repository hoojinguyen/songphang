import { allocateByWeights } from "./allocate.ts";
import { parseHundredths } from "./decimal.ts";
import {
	allocateNetExtras,
	computeItemShares,
	type ExtrasAllocation,
	type ItemExtraEntry,
	type ItemsSplitInput,
	sumNetExtras,
	validateRatePercentExtras,
} from "./split-items.ts";

export type Share = { memberId: string; amount: number };
export type SplitInput =
	| {
			method: "equal";
			members: readonly string[];
			extras?: readonly ItemExtraEntry[] | undefined;
			extrasAllocation?: ExtrasAllocation | undefined;
	  }
	| {
			method: "exact";
			members: readonly string[];
			entries: readonly Share[];
			remainder: "none" | "equal_among_blank" | "equal_among_all";
			extras?: readonly ItemExtraEntry[] | undefined;
			extrasAllocation?: ExtrasAllocation | undefined;
	  }
	| {
			method: "shares";
			entries: readonly { memberId: string; weight: string }[];
			extras?: readonly ItemExtraEntry[] | undefined;
			extrasAllocation?: ExtrasAllocation | undefined;
	  }
	| {
			method: "percent";
			entries: readonly { memberId: string; percent: string }[];
			extras?: readonly ItemExtraEntry[] | undefined;
			extrasAllocation?: ExtrasAllocation | undefined;
	  }
	| ItemsSplitInput;

export type SplitResult =
	| { ok: true; shares: Share[] }
	| {
			ok: false;
			code: "SPLIT_TOTAL_MISMATCH";
			expected: number;
			actual: number;
	  }
	| {
			ok: false;
			code: "ITEM_UNASSIGNED";
			itemIndex: number;
	  };

function validIds(ids: readonly string[]) {
	if (
		ids.length === 0 ||
		ids.some((id) => id.length === 0) ||
		new Set(ids).size !== ids.length
	)
		throw new RangeError("Member IDs must be nonempty and unique");
}

function validAmount(amount: number) {
	if (!Number.isSafeInteger(amount) || amount < 0)
		throw new RangeError("Amount must be a nonnegative safe integer");
}

function mismatch(expected: number, actual: number): SplitResult {
	return { ok: false, code: "SPLIT_TOTAL_MISMATCH", expected, actual };
}

export function splitEqually(
	amount: number,
	memberIdsByPosition: readonly string[],
): Share[] {
	validAmount(amount);
	if (amount === 0) throw new RangeError("Amount must be positive");
	validIds(memberIdsByPosition);
	const amounts = allocateByWeights(
		amount,
		memberIdsByPosition.map(() => 1n),
	);
	return memberIdsByPosition.map((memberId, index) => ({
		memberId,
		amount: amounts[index] ?? 0,
	}));
}

function exactShares(
	amount: number,
	split: Extract<SplitInput, { method: "exact" }>,
	ids: readonly string[],
): SplitResult {
	const entries = new Map(
		split.entries.map((entry) => {
			validAmount(entry.amount);
			return [entry.memberId, entry.amount] as const;
		}),
	);
	if (
		entries.size !== split.entries.length ||
		split.entries.some((entry) => !ids.includes(entry.memberId))
	)
		throw new RangeError("Invalid exact entries");
	const total = split.entries.reduce((sum, entry) => sum + entry.amount, 0);
	validAmount(total);
	const blank = ids.filter((id) => !entries.has(id));
	if (
		total > amount ||
		((split.remainder === "none" ||
			(split.remainder === "equal_among_blank" && blank.length === 0)) &&
			total !== amount)
	)
		return mismatch(amount, total);
	if (split.remainder === "none" && blank.length > 0)
		throw new RangeError("Exact split requires every member");
	const weights = ids.map((id) =>
		split.remainder === "equal_among_all" ||
		(split.remainder === "equal_among_blank" && !entries.has(id))
			? 1n
			: 0n,
	);
	const extra =
		amount === total
			? ids.map(() => 0)
			: allocateByWeights(amount - total, weights);
	return {
		ok: true,
		shares: ids.map((memberId, index) => ({
			memberId,
			amount: (entries.get(memberId) ?? 0) + (extra[index] ?? 0),
		})),
	};
}

function computeBaseShares(
	baseSubtotal: number,
	split: Exclude<SplitInput, { method: "items" }>,
	ids: readonly string[],
): SplitResult {
	if (split.method === "equal") {
		return { ok: true, shares: splitEqually(baseSubtotal, ids) };
	}
	if (split.method === "exact") {
		return exactShares(baseSubtotal, split, ids);
	}
	const weights = ids.map((id) => {
		const entry = split.entries.find((entry) => entry.memberId === id);
		if (!entry) throw new RangeError("Missing split entry");
		return parseHundredths("weight" in entry ? entry.weight : entry.percent);
	});
	const sum = weights.reduce((total, weight) => total + weight, 0n);
	if (split.method === "percent" && sum !== 10000n) {
		return mismatch(100, Number(sum / 100n));
	}
	if (sum === 0n) return mismatch(baseSubtotal, 0);
	const amounts = allocateByWeights(baseSubtotal, weights);
	return {
		ok: true,
		shares: ids.map((memberId, index) => ({
			memberId,
			amount: amounts[index] ?? 0,
		})),
	};
}

export function computeShares(
	amount: number,
	split: SplitInput,
	memberIdsByPosition: readonly string[],
): SplitResult {
	if (split.method === "items") {
		return computeItemShares(amount, split, memberIdsByPosition);
	}
	validAmount(amount);
	if (amount === 0) throw new RangeError("Amount must be positive");
	validIds(memberIdsByPosition);
	const participants =
		split.method === "equal" || split.method === "exact"
			? split.members
			: split.entries.map((entry) => entry.memberId);
	validIds(participants);
	if (participants.some((id) => !memberIdsByPosition.includes(id)))
		throw new RangeError("Unknown member ID");
	const ids = memberIdsByPosition.filter((id) => participants.includes(id));

	const extras = split.extras ?? [];
	const netExtras = sumNetExtras(extras);
	const baseSubtotal = extras.length === 0 ? amount : amount - netExtras;
	if (!Number.isSafeInteger(baseSubtotal) || baseSubtotal <= 0) {
		return mismatch(amount, Math.max(0, netExtras));
	}
	const rateFailure = validateRatePercentExtras(baseSubtotal, extras);
	if (rateFailure !== null) return rateFailure;

	const baseResult = computeBaseShares(baseSubtotal, split, ids);
	if (!baseResult.ok || netExtras === 0) {
		return baseResult;
	}

	const allocation: ExtrasAllocation = split.extrasAllocation ?? "equal";
	const allocated = allocateNetExtras(
		baseResult.shares.map((share) => share.amount),
		netExtras,
		allocation,
	);
	if (!allocated.ok) return allocated;

	return {
		ok: true,
		shares: baseResult.shares.map((share, index) => ({
			memberId: share.memberId,
			amount: allocated.amounts[index] ?? 0,
		})),
	};
}
