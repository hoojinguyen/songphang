import { readFile } from "node:fs/promises";
import path from "node:path";
import { z } from "@hono/zod-openapi";
import { SentenceAiAnswer } from "@songphang/contract";
import type {
	SentenceAi,
	SentenceAiInput,
	SentenceAiOutput,
} from "./sentence-ai.js";

const FIXTURES_PATH = path.resolve(
	import.meta.dirname,
	"../../fixtures/sentences.json",
);

const FIXTURE_ENTRY_SCHEMA = z.object({
	sentence: z.string(),
	answer: SentenceAiAnswer,
});
const FIXTURES_SCHEMA = z.array(FIXTURE_ENTRY_SCHEMA);

function normalizeKey(sentence: string): string {
	return sentence.normalize("NFC").trim().toLowerCase();
}

function mapNameToRef(
	name: string,
	members: ReadonlyArray<{ ref: string; name: string }>,
): string {
	const normalized = normalizeKey(name);
	const matches = members.filter((m) => normalizeKey(m.name) === normalized);
	return matches.length === 1 && matches[0]
		? matches[0].ref
		: `foreign:${name}`;
}

export function createFakeSentenceAi(): SentenceAi {
	return {
		async read(input: SentenceAiInput): Promise<SentenceAiOutput> {
			const raw = await readFile(FIXTURES_PATH, "utf8");
			const fixtures = FIXTURES_SCHEMA.parse(JSON.parse(raw));
			const target = normalizeKey(input.sentence);
			const match = fixtures.find(
				(entry) => normalizeKey(entry.sentence) === target,
			);
			if (!match) {
				return {
					answer: { drafts: [] },
					model: "fake-sentence-v1",
					inputTokens: 0,
					outputTokens: 0,
				};
			}

			const mappedDrafts = match.answer.drafts.map((draft) => {
				const payerRef =
					draft.payerRef === null
						? null
						: mapNameToRef(draft.payerRef, input.members);
				const split =
					draft.split.method === "equal"
						? {
								method: "equal" as const,
								members: draft.split.members.map((name) =>
									mapNameToRef(name, input.members),
								),
							}
						: draft.split.method === "exact"
							? {
									method: "exact" as const,
									members: draft.split.members.map((name) =>
										mapNameToRef(name, input.members),
									),
									entries: draft.split.entries.map((entry) => ({
										memberId: mapNameToRef(entry.memberId, input.members),
										amount: entry.amount,
									})),
									remainder: draft.split.remainder,
								}
							: draft.split.method === "shares"
								? {
										method: "shares" as const,
										entries: draft.split.entries.map((entry) => ({
											memberId: mapNameToRef(entry.memberId, input.members),
											weight: entry.weight,
										})),
									}
								: {
										method: "percent" as const,
										entries: draft.split.entries.map((entry) => ({
											memberId: mapNameToRef(entry.memberId, input.members),
											percent: entry.percent,
										})),
									};
				return {
					...draft,
					payerRef,
					split,
				};
			});

			return {
				answer: { drafts: mappedDrafts },
				model: "fake-sentence-v1",
				inputTokens: 0,
				outputTokens: 0,
			};
		},
	};
}
