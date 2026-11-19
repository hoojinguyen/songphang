import { randomBytes } from "node:crypto";
import { AnthropicTransportError, type AnthropicUsage } from "@songphang/ai";
import { ParseResponse, SentenceAiAnswer } from "@songphang/contract";
import { quotaWindowStarts } from "@songphang/core";
import {
	claimAiCall,
	type listGroupMembers,
	recordAiCall,
	reserveAiCall,
} from "@songphang/db";
import {
	type SentenceAi,
	type SentenceAiInput,
	selectSentenceAi,
} from "../ai/sentence-ai.js";
import type { AppDeps } from "../app.js";
import { mapAiDraftToResult } from "./quick-entry-ai-draft.js";
import type { CustomCategory } from "./quick-entry-category.js";

type GroupMembers = Awaited<ReturnType<typeof listGroupMembers>>;
type SentenceAiAnswerData = ReturnType<typeof SentenceAiAnswer.parse>;

async function startSentenceAttempt(
	deps: AppDeps,
	caller: { userId: string; groupId: string },
): Promise<string | null> {
	const now = deps.now();
	const reservation = await reserveAiCall(deps.db, {
		purpose: "sentence",
		...caller,
		limits: {
			userDaily: deps.config.aiSentencesPerUserPerDay,
			monthTotal: deps.config.aiCallsPerMonth,
		},
		now,
	});
	if (reservation.status !== "ok") return null;
	const claim = await claimAiCall(deps.db, {
		id: reservation.reservationId,
		purpose: "sentence",
		...caller,
		receiptScanId: null,
		minCreatedAt: quotaWindowStarts(now).dayStart,
		startedAt: now,
	});
	if (!claim) {
		await finishSentenceAttempt(deps, reservation.reservationId, null, false);
		return null;
	}
	return reservation.reservationId;
}

async function finishSentenceAttempt(
	deps: AppDeps,
	reservationId: string,
	usage: AnthropicUsage | null,
	ok: boolean,
): Promise<void> {
	await recordAiCall(deps.db, {
		id: reservationId,
		model: usage?.model ?? deps.config.aiModel ?? "",
		inputTokens: usage?.inputTokens ?? 0,
		outputTokens: usage?.outputTokens ?? 0,
		ok,
		finishedAt: deps.now(),
	});
}

function buildMemberReferences(members: GroupMembers, memberId: string | null) {
	const nonce = randomBytes(4).toString("hex");
	const refMembers = members
		.filter((member) => member.kind === "person" && member.active)
		.map((member, index) => ({
			id: member.id,
			ref: `${nonce}:p${index + 1}`,
			name: member.name,
		}));
	return {
		refMembers: refMembers.map(({ ref, name }) => ({ ref, name })),
		refToId: new Map(refMembers.map((item) => [item.ref, item.id])),
		writerRef: refMembers.find((item) => item.id === memberId)?.ref ?? null,
	};
}

async function askSentenceAi(
	deps: AppDeps,
	sentenceAi: SentenceAi,
	reservationId: string,
	request: SentenceAiInput,
): Promise<SentenceAiAnswerData | null> {
	try {
		const output = await sentenceAi.read(request);
		const answer = SentenceAiAnswer.safeParse(output.answer);
		await finishSentenceAttempt(deps, reservationId, output, answer.success);
		return answer.success ? answer.data : null;
	} catch (error) {
		const usage = error instanceof AnthropicTransportError ? error.usage : null;
		await finishSentenceAttempt(deps, reservationId, usage, false);
		return null;
	}
}

// Called only for an explicitly sent sentence the rule reader refused; any failure returns the rule answer.
export async function readWithSentenceAi(
	deps: AppDeps,
	input: {
		groupId: string;
		userId: string;
		memberId: string | null;
		text: string;
		members: GroupMembers;
		customCategories: readonly CustomCategory[];
		rulesResponse: ParseResponse;
	},
): Promise<ParseResponse> {
	const { text, members, rulesResponse } = input;
	const sentenceAi =
		deps.sentenceAi !== undefined
			? deps.sentenceAi
			: selectSentenceAi(deps.config);
	if (!sentenceAi) return rulesResponse;
	const reservationId = await startSentenceAttempt(deps, {
		userId: input.userId,
		groupId: input.groupId,
	});
	if (!reservationId) return rulesResponse;
	const references = buildMemberReferences(members, input.memberId);
	const answer = await askSentenceAi(deps, sentenceAi, reservationId, {
		sentence: text,
		members: references.refMembers,
		writerRef: references.writerRef,
	});
	const results = (answer?.drafts ?? []).map((aiDraft) =>
		mapAiDraftToResult(aiDraft, {
			refToId: references.refToId,
			allMemberIds: members.map((member) => member.id),
			text,
			fallbackDraft: rulesResponse.draft,
			customCategories: input.customCategories,
		}),
	);
	const [first, ...rest] = results;
	if (!first) return rulesResponse;
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
