import Link from "next/link";
import { formatMoney } from "../../lib/money";
import { t, vi } from "../../messages/vi";

export function MemberStatsRow({
	name,
	paid,
	share,
	maxAmount,
	href,
}: {
	name: string;
	paid: number;
	share: number;
	maxAmount: number;
	href: string;
}) {
	const paidWidth =
		maxAmount > 0 && paid > 0 ? Math.min(100, (paid / maxAmount) * 100) : 0;
	const shareWidth =
		maxAmount > 0 && share > 0 ? Math.min(100, (share / maxAmount) * 100) : 0;
	return (
		<Link
			href={href}
			className="grid min-h-11 gap-1.5 rounded-[18px] px-2 py-2"
		>
			<p className="break-words text-sm font-bold text-ink">
				{t(vi.stats.memberRow, {
					name,
					paid: formatMoney(paid),
					share: formatMoney(share),
				})}
			</p>
			<div className="grid gap-1">
				<div className="h-2 overflow-hidden rounded-pill bg-sunken">
					{paidWidth > 0 && (
						<div
							className="h-full rounded-pill bg-ink"
							style={{ width: `${paidWidth}%` }}
						/>
					)}
				</div>
				<div className="h-2 overflow-hidden rounded-pill bg-sunken">
					{shareWidth > 0 && (
						<div
							className="h-full rounded-pill bg-mint"
							style={{ width: `${shareWidth}%` }}
						/>
					)}
				</div>
			</div>
		</Link>
	);
}
