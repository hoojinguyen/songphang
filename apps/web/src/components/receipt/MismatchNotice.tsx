"use client";
import { formatMoney } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { Button } from "../ui/Button";

export function MismatchNotice({
	computed,
	printedTotal,
	extrasFull,
	printedPending = false,
	onUseComputed,
	onUsePrintedTotal,
}: {
	computed: number;
	printedTotal: number;
	extrasFull: boolean;
	printedPending?: boolean;
	onUseComputed: () => void;
	onUsePrintedTotal: () => void;
}) {
	return (
		<div
			role="status"
			className="grid gap-3 rounded-[26px] bg-phrase-amount p-4 text-ink"
		>
			<p className="text-sm font-bold">
				{t(vi.receipts.mismatch, {
					computed: formatMoney(computed),
					total: formatMoney(printedTotal),
				})}
			</p>
			{extrasFull && (
				<p role="alert" className="text-xs font-extrabold">
					{vi.receipts.maxExtras}
				</p>
			)}
			<div className="flex flex-wrap gap-2">
				<Button type="button" variant="surface" onClick={onUseComputed}>
					{t(vi.receipts.useAmount, { amount: formatMoney(computed) })}
				</Button>
				<Button
					type="button"
					variant="primary"
					disabled={extrasFull || printedPending}
					onClick={onUsePrintedTotal}
				>
					{t(vi.receipts.useAmount, { amount: formatMoney(printedTotal) })}
				</Button>
			</div>
		</div>
	);
}
