import { foldVietnamese } from "./normalize.ts";
export type Token = {
	raw: string;
	value: string;
	start: number;
	end: number;
	kind: "word" | "number" | "punct";
};
export type SpanKind =
	| "amount"
	| "description"
	| "payer"
	| "equal"
	| "exact"
	| "remainder";
export type Span = { start: number; end: number; kind: SpanKind };
export type QuickEntryIssueCode =
	| "AMOUNT_MISSING"
	| "DESCRIPTION_MISSING"
	| "MEMBER_AMBIGUOUS"
	| "MEMBER_UNKNOWN"
	| "COUNT_MISMATCH"
	| "SUM_MISMATCH"
	| "FUND_CANNOT_SHARE"
	| "TEXT_NOT_UNDERSTOOD";
export type Issue = {
	code: QuickEntryIssueCode;
	start: number;
	end: number;
	candidates: string[];
	count?: number;
	expected?: number;
	actual?: number;
};
export function tokenize(text: string): Token[] {
	const folded = foldVietnamese(text);
	const pattern =
		/\d+(?:[.,]\d+)*(?:\s*(?:nghin|ngan|trieu|tr|k)(?:\d+)?)?(?=$|[^\p{L}\p{N}])|[\p{L}\p{M}]+|[^\s]/gu;
	return Array.from(folded.matchAll(pattern), (match) => ({
		raw: text.slice(match.index, match.index + match[0].length),
		value: match[0],
		start: match.index,
		end: match.index + match[0].length,
		kind: /^\d/.test(match[0])
			? "number"
			: /^[\p{L}\p{M}]/u.test(match[0])
				? "word"
				: "punct",
	}));
}
export function mergeSpans(text: string, spans: Span[]): Span[] {
	const result: Span[] = [];
	for (const span of spans.toSorted((a, b) => a.start - b.start)) {
		const previous = result.at(-1);
		if (
			previous?.kind === span.kind &&
			/^[\s,.;:]*$/.test(text.slice(previous.end, span.start))
		)
			previous.end = span.end;
		else if (!previous || span.start >= previous.end) result.push({ ...span });
	}
	return result;
}
