import { randomBytes } from "node:crypto";
import {
	type AiSentenceDraft,
	ParseDraft,
	type ParsedDraftResult,
	type ParseRequest,
	ParseResponse,
	SentenceAiAnswer,
	SplitInput,
	TransactionCategory,
} from "@songphang/contract";
import {
	computeShares,
	quotaWindowStarts,
	readSentence,
	suggestCategory,
} from "@songphang/core";
import {
	claimAiCall,
	listGroupCategories,
	listGroupMembers,
	recordAiCall,
	reserveAiCall,
} from "@songphang/db";
import { selectSentenceAi } from "../ai/sentence-ai.js";
import type { AppDeps } from "../app.js";

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

function applySuggestedCategory(
	draft: ParseDraft,
	customCategories: ReadonlyArray<{ id: string; nameKey: string }>,
): ParseDraft {
	if (
		draft.category !== null ||
		draft.categoryId !== null ||
		!draft.description
	) {
		return draft;
	}
	const suggestion = suggestCategory(draft.description, customCategories);
	if (!suggestion) {
		return draft;
	}
	if ("categoryId" in suggestion) {
		return ParseDraft.parse({
			...draft,
			category: null,
			categoryId: suggestion.categoryId,
		});
	}
	const builtIn = TransactionCategory.safeParse(suggestion.category);
	if (!builtIn.success) {
		return draft;
	}
	return ParseDraft.parse({
		...draft,
		category: builtIn.data,
		categoryId: null,
	});
}

function mapAiDraftToResult(
	aiDraft: AiSentenceDraft,
	refToId: ReadonlyMap<string, string>,
	allMemberIds: readonly string[],
	text: string,
	fallbackDraft: ParseDraft,
	customCategories: ReadonlyArray<{ id: string; nameKey: string }>,
): ParsedDraftResult {
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

	const sentenceAi =
		deps.sentenceAi !== undefined
			? deps.sentenceAi
			: selectSentenceAi(deps.config);
	if (!sentenceAi) {
		return rulesResponse;
	}

	const now = deps.now();
	const reservation = await reserveAiCall(deps.db, {
		purpose: "sentence",
		userId: input.userId,
		groupId: input.groupId,
		limits: {
			userDaily: deps.config.aiSentencesPerUserPerDay,
			monthTotal: deps.config.aiCallsPerMonth,
		},
		now,
	});
	if (reservation.status !== "ok") {
		return rulesResponse;
	}

	const { dayStart } = quotaWindowStarts(now);
	const claim = await claimAiCall(deps.db, {
		id: reservation.reservationId,
		purpose: "sentence",
		userId: input.userId,
		groupId: input.groupId,
		receiptScanId: null,
		minCreatedAt: dayStart,
		startedAt: now,
	});
	if (!claim) {
		await recordAiCall(deps.db, {
			id: reservation.reservationId,
			model: deps.config.aiModel ?? "",
			inputTokens: 0,
			outputTokens: 0,
			ok: false,
			finishedAt: deps.now(),
		});
		return rulesResponse;
	}

	const activePeople = members.filter(
		(member) => member.kind === "person" && member.active,
	);
	const nonce = randomBytes(4).toString("hex");
	const refMembers = activePeople.map((member, index) => ({
		id: member.id,
		ref: `${nonce}:p${index + 1}`,
		name: member.name,
	}));
	const refToId = new Map(refMembers.map((item) => [item.ref, item.id]));
	const writerRef =
		refMembers.find((item) => item.id === input.memberId)?.ref ?? null;

	let aiOutput: Awaited<ReturnType<typeof sentenceAi.read>>;
	try {
		aiOutput = await sentenceAi.read({
			sentence: text,
			members: refMembers.map(({ ref, name }) => ({ ref, name })),
			writerRef,
		});
	} catch {
		await recordAiCall(deps.db, {
			id: reservation.reservationId,
			model: deps.config.aiModel ?? "",
			inputTokens: 0,
			outputTokens: 0,
			ok: false,
			finishedAt: deps.now(),
		});
		return rulesResponse;
	}

	const parsedAnswer = SentenceAiAnswer.safeParse(aiOutput.answer);
	if (!parsedAnswer.success) {
		await recordAiCall(deps.db, {
			id: reservation.reservationId,
			model: aiOutput.model,
			inputTokens: aiOutput.inputTokens,
			outputTokens: aiOutput.outputTokens,
			ok: false,
			finishedAt: deps.now(),
		});
		return rulesResponse;
	}

	await recordAiCall(deps.db, {
		id: reservation.reservationId,
		model: aiOutput.model,
		inputTokens: aiOutput.inputTokens,
		outputTokens: aiOutput.outputTokens,
		ok: true,
		finishedAt: deps.now(),
	});

	if (parsedAnswer.data.drafts.length === 0) {
		return rulesResponse;
	}

	const allMemberIds = members.map((m) => m.id);
	const results = parsedAnswer.data.drafts.map((aiDraft) =>
		mapAiDraftToResult(
			aiDraft,
			refToId,
			allMemberIds,
			text,
			rulesResponse.draft,
			customCategories,
		),
	);
	const [first, ...rest] = results;
	if (!first) {
		return rulesResponse;
	}

	return ParseResponse.parse({
		status: first.status,
		text,
		draft: first.draft,
		...(first.shares ? { shares: first.shares } : {}),
		spans: [],
		issues: first.issues,
		reader: "ai",
		moreDrafts: rest.slice(0, 4),
	});
}
