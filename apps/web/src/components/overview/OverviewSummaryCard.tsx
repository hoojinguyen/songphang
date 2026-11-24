"use client";
import type { OverviewResponse } from "@songphang/contract";
import { formatMoney, formatSignedAmount } from "../../lib/money";
import { vi } from "../../messages/vi";

export function OverviewSummaryCard({
	overview,
}: {
	overview: OverviewResponse;
}) {
	const allSettled =
		overview.totalOwedToMe === 0 &&
		overview.totalIOwe === 0 &&
		overview.netBalance === 0;

	const tone =
		overview.netBalance > 0
			? "bg-accent"
			: overview.netBalance < 0
				? "bg-debt-soft"
				: "bg-surface";

	return (
		<section
			aria-label={vi.overview.title}
			className={`rounded-[36px] p-6 text-ink ${tone}`}
		>
			<p className="text-xs font-bold uppercase tracking-wider text-muted">
				{vi.overview.netBalance}
			</p>
			<p className="break-words text-[44px] font-black leading-tight tracking-tight">
				{formatSignedAmount(overview.netBalance)}{" "}
				<span className="text-xl font-bold text-muted">
					{vi.common.currency}
				</span>
			</p>
			{allSettled ? (
				<p className="mt-2 text-sm font-semibold text-muted">
					{vi.overview.allSettled}
				</p>
			) : (
				<div className="mt-4 grid grid-cols-2 gap-3 border-t border-ink/10 pt-4">
					<div>
						<p className="text-xs font-medium text-muted">
							{vi.overview.totalOwedToMe}
						</p>
						<p className="text-lg font-black text-credit">
							+{formatMoney(overview.totalOwedToMe)}
						</p>
					</div>
					<div>
						<p className="text-xs font-medium text-muted">
							{vi.overview.totalIOwe}
						</p>
						<p className="text-lg font-black text-debt">
							−{formatMoney(overview.totalIOwe)}
						</p>
					</div>
				</div>
			)}
		</section>
	);
}
