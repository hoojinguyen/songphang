import { foldVietnamese } from "./normalize.ts";
import type { Issue, Token } from "./tokens.ts";
export type QuickEntryMember = {
	id: string;
	name: string;
	active: boolean;
	position: number;
};
export type NameResult = {
	memberId: string | null;
	candidates: string[];
	length: number;
};
export type ReaderContext = {
	text: string;
	tokens: Token[];
	members: QuickEntryMember[];
	writerMemberId: string | null;
	memberChoices: Readonly<Record<number, string>>;
	used: Set<number>;
	spans: import("./tokens.ts").Span[];
	issues: Issue[];
};
export function readName(context: ReaderContext, start: number): NameResult {
	const first = context.tokens[start];
	if (first?.kind !== "word")
		return { memberId: null, candidates: [], length: 0 };
	const writer = context.writerMemberId;
	const pronoun =
		["toi", "to"].includes(first.value) ||
		first.raw.toLocaleLowerCase("vi") === "mình";
	const pronounChoice = context.memberChoices[first.start];
	const pronounWriter =
		writer ??
		(context.members.some((m) => m.id === pronounChoice)
			? pronounChoice
			: null);
	if (pronoun)
		return pronounWriter
			? { memberId: pronounWriter, candidates: [pronounWriter], length: 1 }
			: {
					memberId: null,
					candidates: context.members.map((m) => m.id),
					length: 1,
				};
	let longest = 0;
	let matches: QuickEntryMember[] = [];
	for (const member of context.members) {
		const words = foldVietnamese(member.name).trim().split(/\s+/);
		if (
			words.every(
				(word, index) =>
					context.tokens[start + index]?.kind === "word" &&
					context.tokens[start + index]?.value === word,
			)
		) {
			if (words.length > longest) {
				longest = words.length;
				matches = [];
			}
			if (words.length === longest) matches.push(member);
		}
	}
	if (longest === 0) {
		longest = 1;
		matches = context.members.filter((member) =>
			foldVietnamese(member.name).split(/\s+/).includes(first.value),
		);
	}
	const ids = new Set(matches.map((member) => member.id));
	if (first.value === "minh" && longest === 1 && writer) ids.add(writer);
	const candidates = context.members
		.filter((member) => ids.has(member.id))
		.map((member) => member.id);
	const chosen = context.memberChoices[first.start];
	if (chosen && candidates.includes(chosen))
		return { memberId: chosen, candidates: [chosen], length: longest };
	return {
		memberId: candidates.length === 1 ? (candidates[0] ?? null) : null,
		candidates,
		length: longest,
	};
}
export function nameIssue(
	context: ReaderContext,
	start: number,
	result: NameResult,
) {
	if (result.memberId) return;
	const first = context.tokens[start];
	const last = context.tokens[start + result.length - 1];
	if (!first || !last) return;
	context.issues.push({
		code: result.candidates.length > 0 ? "MEMBER_AMBIGUOUS" : "MEMBER_UNKNOWN",
		start: first.start,
		end: last.end,
		candidates: result.candidates,
	});
}
export function consume(
	context: ReaderContext,
	start: number,
	end: number,
	kind: import("./tokens.ts").SpanKind,
) {
	const first = context.tokens[start];
	const last = context.tokens[end - 1];
	if (!first || !last) return;
	for (let index = start; index < end; index++) context.used.add(index);
	context.spans.push({ start: first.start, end: last.end, kind });
}
