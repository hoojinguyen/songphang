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

	const isPositive = overview.netBalance > 0;
	const isNegative = overview.netBalance < 0;

	const tone = isPositive
		? "bg-accent text-on-accent"
		: isNegative
			? "bg-debt-soft text-ink"
			: "bg-surface text-ink";

	const mutedClass = isPositive ? "text-on-accent/75" : "text-muted";
	const borderClass = isPositive ? "border-on-accent/15" : "border-ink/10";
	const creditClass = isPositive ? "text-[#0e7a4b]" : "text-credit";
	const debtClass = isPositive ? "text-[#a32212]" : "text-debt";

	return (
		<section
			aria-label={vi.overview.title}
			className={`rounded-[36px] p-6 ${tone}`}
		>
			<p className={`text-xs font-bold uppercase tracking-wider ${mutedClass}`}>
				{vi.overview.netBalance}
			</p>
			<p className="break-words text-[44px] font-black leading-tight tracking-tight">
				{formatSignedAmount(overview.netBalance)}{" "}
				<span className={`text-xl font-bold ${mutedClass}`}>
					{vi.common.currency}
				</span>
			</p>
			{allSettled ? (
				<p className={`mt-2 text-sm font-semibold ${mutedClass}`}>
					{vi.overview.allSettled}
				</p>
			) : (
				<div
					className={`mt-4 grid grid-cols-2 gap-3 border-t pt-4 ${borderClass}`}
				>
					<div>
						<p className={`text-xs font-medium ${mutedClass}`}>
							{vi.overview.totalOwedToMe}
						</p>
						<p className={`text-lg font-black ${creditClass}`}>
							+{formatMoney(overview.totalOwedToMe)}
						</p>
					</div>
					<div>
						<p className={`text-xs font-medium ${mutedClass}`}>
							{vi.overview.totalIOwe}
						</p>
						<p className={`text-lg font-black ${debtClass}`}>
							−{formatMoney(overview.totalIOwe)}
						</p>
					</div>
				</div>
			)}
		</section>
	);
}
