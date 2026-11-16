import type { SplitInput } from "../split.ts";
import { readAmount } from "./amounts.ts";
import type { QuickEntryMember, ReaderContext } from "./names.ts";
import { readParts } from "./parts.ts";
import { readEqual, readPayers, readRemainder } from "./phrases.ts";
import { type Issue, mergeSpans, type Span, tokenize } from "./tokens.ts";

export type { QuickEntryMember } from "./names.ts";
export type { QuickEntryIssueCode, SpanKind } from "./tokens.ts";
export type QuickEntryResult = {
	status: "ok" | "needs_input" | "unparsed";
	draft: {
		description: string | null;
		amount: number | null;
		payerMemberId: string | null;
		split: SplitInput | null;
	};
	spans: Span[];
	issues: Issue[];
};
function descriptionOf(context: ReaderContext, end: number): string | null {
	const pieces: string[] = [];
	let start = 0;
	for (const span of context.spans
		.filter((span) => span.kind === "payer" && span.start < end)
		.toSorted((a, b) => a.start - b.start)) {
		addDescription(context, start, span.start, pieces);
		start = span.end;
	}
	addDescription(context, start, end, pieces);
	const description = pieces.join(" ").replace(/\s+/g, " ").trim();
	if (description.length > 200)
		context.issues.push({
			code: "TEXT_NOT_UNDERSTOOD",
			start: 0,
			end,
			candidates: [],
		});
	if (!description)
		context.issues.push({
			code: "DESCRIPTION_MISSING",
			start: 0,
			end: 0,
			candidates: [],
		});
	return description || null;
}
function addDescription(
	context: ReaderContext,
	start: number,
	end: number,
	pieces: string[],
) {
	const raw = context.text.slice(start, end);
	const trimmed = raw.replace(/^[\s,.;:]+|[\s,.;:]+$/g, "");
	if (!trimmed) return;
	const offset = raw.indexOf(trimmed);
	pieces.push(trimmed);
	context.spans.push({
		start: start + offset,
		end: start + offset + trimmed.length,
		kind: "description",
	});
	for (const [index, token] of context.tokens.entries())
		if (token.start >= start && token.end <= end) context.used.add(index);
}
function unreadText(context: ReaderContext, start: number) {
	let begin: number | null = null;
	let end = 0;
	const flush = () => {
		if (begin !== null)
			context.issues.push({
				code: "TEXT_NOT_UNDERSTOOD",
				start: begin,
				end,
				candidates: [],
			});
		begin = null;
	};
	for (let index = start; index < context.tokens.length; index++) {
		const token = context.tokens[index];
		if (!token) continue;
		if (context.used.has(index)) {
			flush();
			continue;
		}
		if (/^[,.;:]$/.test(token.value)) continue;
		begin ??= token.start;
		end = token.end;
	}
	flush();
}
export function readSentence(input: {
	text: string;
	members: readonly QuickEntryMember[];
	writerMemberId: string | null;
	memberChoices?: Readonly<Record<number, string>>;
}): QuickEntryResult {
	const members = input.members
		.filter((member) => member.active)
		.toSorted((a, b) => a.position - b.position);
	const context: ReaderContext = {
		text: input.text,
		tokens: tokenize(input.text),
		members,
		writerMemberId: members.some((member) => member.id === input.writerMemberId)
			? input.writerMemberId
			: null,
		memberChoices: input.memberChoices ?? {},
		used: new Set(),
		spans: [],
		issues: [],
	};
	const payer = readPayers(context);
	const totalIndex = context.tokens.findIndex(
		(token) => token.kind === "number" && readAmount(token.value) !== null,
	);
	const total = context.tokens[totalIndex];
	const amount = total ? readAmount(total.value) : null;
	const description = descriptionOf(context, total?.start ?? input.text.length);
	let split: SplitInput | null = {
		method: "equal",
		members: members.map((member) => member.id),
	};
	if (total && amount !== null) {
		context.used.add(totalIndex);
		context.spans.push({ start: total.start, end: total.end, kind: "amount" });
		const remainder = readRemainder(context, totalIndex);
		const equal = readEqual(context, totalIndex);
		split =
			readParts(context, {
				totalIndex,
				amount,
				remainder,
				hasEqual: equal.explicit,
			}) ?? equal.split;
		unreadText(context, totalIndex + 1);
	} else
		context.issues.push({
			code: "AMOUNT_MISSING",
			start: 0,
			end: input.text.length,
			candidates: [],
		});
	if (
		members.length === 0 &&
		!context.issues.some((issue) => issue.code === "COUNT_MISMATCH")
	)
		context.issues.push({
			code: "COUNT_MISMATCH",
			count: 1,
			candidates: [],
			start: 0,
			end: 0,
		});
	const unparsed =
		members.length === 0 ||
		context.issues.some(
			(issue) =>
				[
					"AMOUNT_MISSING",
					"MEMBER_UNKNOWN",
					"SUM_MISMATCH",
					"TEXT_NOT_UNDERSTOOD",
				].includes(issue.code) ||
				(issue.code === "COUNT_MISMATCH" &&
					(issue.count ?? 0) > members.length),
		);
	return {
		status: unparsed
			? "unparsed"
			: context.issues.length > 0
				? "needs_input"
				: "ok",
		draft: {
			description,
			amount,
			payerMemberId: payer.payerMemberId,
			split: members.length === 0 ? null : split,
		},
		spans: mergeSpans(input.text, context.spans),
		issues: context.issues.toSorted((a, b) => a.start - b.start),
	};
}
