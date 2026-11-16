import type { ParseResponse } from "@songphang/contract";
import { vi } from "../../messages/vi";

const labels = {
	amount: vi.compose.kindAmount,
	payer: vi.compose.kindPayer,
	equal: vi.compose.kindSplit,
	exact: vi.compose.kindSplit,
	remainder: vi.compose.kindRest,
	description: undefined,
};
export function HighlightedSentence({
	text,
	spans,
}: {
	text: string;
	spans: ParseResponse["spans"];
}) {
	let cursor = 0;
	const parts = [];
	for (const span of spans) {
		if (span.start < cursor || span.end > text.length) continue;
		parts.push(
			<span key={`gap-${span.start}`}>{text.slice(cursor, span.start)}</span>,
		);
		parts.push(
			span.kind === "description" ? (
				<span key={span.start}>{text.slice(span.start, span.end)}</span>
			) : (
				<mark
					role="img"
					key={span.start}
					className={`phrase-mark phrase-${span.kind}`}
					aria-label={`${labels[span.kind]}: ${text.slice(span.start, span.end)}`}
				>
					{text.slice(span.start, span.end)}
				</mark>
			),
		);
		cursor = span.end;
	}
	return (
		<>
			{parts}
			{text.slice(cursor)}
		</>
	);
}
