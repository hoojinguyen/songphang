import type { SplitInput } from "@songphang/contract";
import { formatMoney } from "../../lib/money";
import { vi } from "../../messages/vi";

const EXTRA_KIND_LABELS = {
	tax: vi.extras.kindTax,
	service: vi.extras.kindService,
	shipping: vi.extras.kindShipping,
	discount: vi.extras.kindDiscount,
	other: vi.extras.kindOther,
} as const;

export function SplitExtrasBreakdown({
	split,
	totalAmount,
}: {
	split: SplitInput;
	totalAmount: number;
}) {
	const extras = split.extras ?? [];
	if (extras.length === 0) return null;

	const netExtras = extras.reduce(
		(sum, extra) =>
			sum + (extra.kind === "discount" ? -extra.amount : extra.amount),
		0,
	);
	const baseAmount = totalAmount - netExtras;
	const allocation =
		split.extrasAllocation ??
		(split.method === "items" ? "proportional" : "equal");
	const allocationLabel =
		allocation === "equal"
			? vi.extras.allocEqualLabel
			: vi.extras.allocProportionalLabel;
	const seenCounts = new Map<string, number>();

	return (
		<section className="grid gap-1.5 rounded-[22px] bg-bg p-3 text-xs">
			<div className="flex items-center justify-between gap-2 font-bold text-ink">
				<span>{vi.extras.goodsSubtotal}</span>
				<span className="tabular-nums">{formatMoney(baseAmount)}</span>
			</div>
			{extras.map((extra) => {
				const baseKey = `${extra.kind}:${extra.label}:${extra.amount}:${extra.ratePercent ?? ""}`;
				const seen = (seenCounts.get(baseKey) ?? 0) + 1;
				seenCounts.set(baseKey, seen);
				const baseLabel = extra.label || EXTRA_KIND_LABELS[extra.kind];
				const title = extra.ratePercent
					? `${baseLabel} (${extra.ratePercent}%)`
					: baseLabel;
				return (
					<div
						key={`${baseKey}#${seen}`}
						className="flex items-center justify-between gap-2 text-muted"
					>
						<span className="min-w-0 break-words font-semibold">{title}</span>
						<span
							className={`shrink-0 tabular-nums font-bold ${
								extra.kind === "discount" ? "text-credit" : "text-ink"
							}`}
						>
							{extra.kind === "discount" ? "−" : "+"}
							{formatMoney(extra.amount)}
						</span>
					</div>
				);
			})}
			<p className="text-[11px] font-semibold text-muted">{allocationLabel}</p>
			<div className="flex items-center justify-between gap-2 border-t border-border-subtle pt-1.5 font-extrabold text-ink">
				<span>{vi.extras.totalPayment}</span>
				<span className="tabular-nums">{formatMoney(totalAmount)}</span>
			</div>
		</section>
	);
}
