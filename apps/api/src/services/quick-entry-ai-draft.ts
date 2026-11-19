import {
	type AiSentenceDraft,
	ParseDraft,
	type ParsedDraftResult,
	SplitInput,
} from "@songphang/contract";
import { computeShares } from "@songphang/core";
import {
	applySuggestedCategory,
	type CustomCategory,
} from "./quick-entry-category.js";

function mapSplitReferences(
	split: AiSentenceDraft["split"],
	refToId: ReadonlyMap<string, string>,
): { split: SplitInput | null; hasUnknownRef: boolean } {
	let hasUnknownRef = false;
	const resolveUnique = (refs: readonly string[]) => {
		const mapped: string[] = [];
		for (const ref of refs) {
			const id = refToId.get(ref);
			if (!id) {
				hasUnknownRef = true;
				continue;
			}
			if (!mapped.includes(id)) mapped.push(id);
		}
		return mapped;
	};

	if (split.method === "equal") {
		const members = resolveUnique(split.members);
		const parsed = SplitInput.safeParse({ method: "equal", members });
		return {
			split: parsed.success ? parsed.data : null,
			hasUnknownRef,
		};
	}

	if (split.method === "exact") {
		const members = resolveUnique(split.members);
		const entries: Array<{ memberId: string; amount: number }> = [];
		for (const entry of split.entries) {
			const id = refToId.get(entry.memberId);
			if (!id) {
				hasUnknownRef = true;
				continue;
			}
			entries.push({ memberId: id, amount: entry.amount });
		}
		const parsed = SplitInput.safeParse({
			method: "exact",
			members,
			entries,
			remainder: split.remainder,
		});
		return {
			split: parsed.success ? parsed.data : null,
			hasUnknownRef,
		};
	}

	if (split.method === "shares") {
		const entries: Array<{ memberId: string; weight: string }> = [];
		for (const entry of split.entries) {
			const id = refToId.get(entry.memberId);
			if (!id) {
				hasUnknownRef = true;
				continue;
			}
			entries.push({ memberId: id, weight: entry.weight });
		}
		const parsed = SplitInput.safeParse({ method: "shares", entries });
		return {
			split: parsed.success ? parsed.data : null,
			hasUnknownRef,
		};
	}

	const entries: Array<{ memberId: string; percent: string }> = [];
	for (const entry of split.entries) {
		const id = refToId.get(entry.memberId);
		if (!id) {
			hasUnknownRef = true;
			continue;
		}
		entries.push({ memberId: id, percent: entry.percent });
	}
	const parsed = SplitInput.safeParse({ method: "percent", entries });
	return {
		split: parsed.success ? parsed.data : null,
		hasUnknownRef,
	};
}

type AiDraftContext = {
	refToId: ReadonlyMap<string, string>;
	allMemberIds: readonly string[];
	text: string;
	fallbackDraft: ParseDraft;
	customCategories: readonly CustomCategory[];
};

export function mapAiDraftToResult(
	aiDraft: AiSentenceDraft,
	context: AiDraftContext,
): ParsedDraftResult {
	const { refToId, allMemberIds, text, fallbackDraft, customCategories } =
		context;
	let hasUnknownRef = false;
	let payers: Array<{ memberId: string; amount: number }> = [];
	if (aiDraft.payerRef !== null) {
		const payerId = refToId.get(aiDraft.payerRef);
		if (!payerId) {
			hasUnknownRef = true;
		} else {
			payers = [{ memberId: payerId, amount: aiDraft.amount }];
		}
	}

	const splitMapped = mapSplitReferences(aiDraft.split, refToId);
	if (splitMapped.hasUnknownRef) {
		hasUnknownRef = true;
	}

	const draftParsed = ParseDraft.safeParse({
		type: "expense",
		description: aiDraft.description,
		amount: aiDraft.amount,
		payers,
		split: splitMapped.split,
		category: aiDraft.category,
		categoryId: null,
	});

	if (!draftParsed.success) {
		return {
			status: "unparsed",
			draft: fallbackDraft,
			issues: [
				{
					code: "TEXT_NOT_UNDERSTOOD",
					start: 0,
					end: text.length,
					candidates: [],
				},
			],
		};
	}

	const enrichedDraft = applySuggestedCategory(
		draftParsed.data,
		customCategories,
	);

	const shareCheck =
		!hasUnknownRef &&
		aiDraft.confident &&
		payers.length === 1 &&
		splitMapped.split !== null
			? computeShares(aiDraft.amount, splitMapped.split, allMemberIds)
			: null;

	if (shareCheck?.ok) {
		return {
			status: "ok",
			draft: enrichedDraft,
			issues: [],
			shares: shareCheck.shares,
		};
	}

	return {
		status: "needs_input",
		draft: enrichedDraft,
		issues: [
			{
				code: "TEXT_NOT_UNDERSTOOD",
				start: 0,
				end: text.length,
				candidates: [],
			},
		],
	};
}
