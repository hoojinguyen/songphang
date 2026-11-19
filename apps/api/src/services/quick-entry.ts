import {
	ParseDraft,
	type ParseRequest,
	ParseResponse,
} from "@songphang/contract";
import { computeShares, readSentence } from "@songphang/core";
import { listGroupCategories, listGroupMembers } from "@songphang/db";
import type { AppDeps } from "../app.js";
import { readWithSentenceAi } from "./quick-entry-ai.js";
import { applySuggestedCategory } from "./quick-entry-category.js";

export async function parseSentence(
	deps: AppDeps,
	input: {
		groupId: string;
		userId: string;
		memberId: string | null;
		request: ParseRequest;
	},
): Promise<ParseResponse> {
	const text = input.request.text.normalize("NFC");
	const [members, categories] = await Promise.all([
		listGroupMembers(deps.db, input.groupId),
		listGroupCategories(deps.db, input.groupId),
	]);
	const customCategories = categories
		.filter((item) => item.archivedAt === null)
		.map((item) => ({ id: item.id, nameKey: item.nameKey }));
	const result = readSentence({
		text,
		members: members.map((member) => ({
			id: member.id,
			name: member.name,
			kind: member.kind === "fund" ? "fund" : "person",
			active: member.active,
			position: member.position,
		})),
		writerMemberId: input.memberId,
	});
	const { payerMemberId, ...draft } = result.draft;
	const shares =
		result.status === "ok" && draft.amount !== null && draft.split
			? computeShares(
					draft.amount,
					draft.split,
					members.map((m) => m.id),
				)
			: null;
	if (shares && !shares.ok) throw new Error("Reader returned an invalid split");

	const ruleBaseDraft = ParseDraft.parse({
		...draft,
		type: "expense",
		payers:
			payerMemberId && draft.amount !== null
				? [{ memberId: payerMemberId, amount: draft.amount }]
				: [],
		category: null,
		categoryId: null,
	});

	const rulesResponse = ParseResponse.parse({
		...result,
		text,
		draft:
			result.status === "unparsed"
				? ruleBaseDraft
				: applySuggestedCategory(ruleBaseDraft, customCategories),
		...(shares?.ok ? { shares: shares.shares } : {}),
		reader: "rules",
		moreDrafts: [],
	});

	if (rulesResponse.status !== "unparsed" || !input.request.ai) {
		return rulesResponse;
	}

	return readWithSentenceAi(deps, {
		groupId: input.groupId,
		userId: input.userId,
		memberId: input.memberId,
		text,
		members,
		customCategories,
		rulesResponse,
	});
}
