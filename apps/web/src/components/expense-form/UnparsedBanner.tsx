"use client";
import { useState } from "react";
import { useDraft } from "../../lib/draft-context";
import { formatMoney } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { HighlightedSentence } from "../quick-entry/HighlightedSentence";
import { Icon } from "../ui/Icon";
export function UnparsedBanner({ activeCount }: { activeCount: number }) {
	const { draft } = useDraft();
	const [closed, setClosed] = useState(false);
	if (
		!draft ||
		closed ||
		!draft.issues.some((i) =>
			[
				"AMOUNT_MISSING",
				"SUM_MISMATCH",
				"MEMBER_UNKNOWN",
				"FUND_CANNOT_SHARE",
				"COUNT_MISMATCH",
				"TEXT_NOT_UNDERSTOOD",
			].includes(i.code),
		)
	)
		return null;
	return (
		<aside className="grid gap-3 rounded-[30px] bg-phrase-amount p-4">
			<div className="flex justify-between gap-2">
				<h2 className="text-xl font-extrabold">{vi.unparsed.title}</h2>
				<button
					type="button"
					aria-label={vi.common.cancel}
					onClick={() => setClosed(true)}
					className="flex size-11 items-center justify-center"
				>
					<Icon name="close" size={20} />
				</button>
			</div>
			<p className="rounded-[18px] bg-surface p-3">
				<HighlightedSentence text={draft.sentence} spans={draft.spans} />
			</p>
			{draft.issues.map((issue) => {
				const word = draft.sentence.slice(issue.start, issue.end);
				const line =
					issue.code === "AMOUNT_MISSING"
						? vi.unparsed.amountMissing
						: issue.code === "SUM_MISMATCH"
							? t(
									(issue.actual ?? 0) < (issue.expected ?? 0)
										? vi.unparsed.sumShort
										: vi.unparsed.sumOver,
									{
										actual: formatMoney(issue.actual ?? 0),
										rest: formatMoney(
											(issue.expected ?? 0) - (issue.actual ?? 0),
										),
										total: formatMoney(issue.expected ?? 0),
									},
								)
							: issue.code === "MEMBER_UNKNOWN"
								? t(vi.unparsed.memberUnknown, { word })
								: issue.code === "FUND_CANNOT_SHARE"
									? vi.unparsed.fundCannotShare
									: issue.code === "COUNT_MISMATCH"
										? t(vi.unparsed.countTooLarge, {
												total: String(activeCount),
											})
										: issue.code === "TEXT_NOT_UNDERSTOOD"
											? t(vi.unparsed.notUnderstood, { fragment: word })
											: null;
				return line ? (
					<p
						key={`${issue.code}-${issue.start}-${issue.end}`}
						className="text-sm"
					>
						{line}
					</p>
				) : null;
			})}
		</aside>
	);
}
