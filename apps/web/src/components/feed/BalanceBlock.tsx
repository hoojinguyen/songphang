import Link from "next/link";
import { formatMoney } from "../../lib/money";
import { vi } from "../../messages/vi";
export function BalanceBlock({
	groupId,
	balance,
}: {
	groupId: string;
	balance: number;
}) {
	const caption =
		balance > 0
			? vi.feed.owedToYou
			: balance < 0
				? vi.feed.youOwe
				: vi.feed.settled;
	const action =
		balance > 0 ? vi.feed.collect : balance < 0 ? vi.feed.pay : vi.feed.view;
	return (
		<Link
			href={`/g/${groupId}/balances`}
			className="flex items-center justify-between gap-2 rounded-[32px] bg-accent pb-4 pl-5 pr-[18px] pt-[14px]"
		>
			<div className="min-w-0">
				<p className="text-[13px] font-semibold">{caption}</p>
				<p className="break-words text-[40px] font-black tracking-tight">
					{formatMoney(Math.abs(balance))}
				</p>
			</div>
			<span className="flex h-12 shrink-0 items-center whitespace-nowrap rounded-pill bg-ink px-5 text-sm font-bold text-surface">
				{action}
			</span>
		</Link>
	);
}
