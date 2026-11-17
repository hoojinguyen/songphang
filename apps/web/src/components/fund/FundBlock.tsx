import type { BalancesResponse, MemberDto } from "@songphang/contract";
import Link from "next/link";
import { formatMoney } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { FundShape } from "../ui/FundShape";

export function FundBlock({
	groupId,
	fund,
	members,
}: {
	groupId: string;
	fund: NonNullable<BalancesResponse["fund"]>;
	members: MemberDto[];
}) {
	const holder = fund.holderMemberId
		? members.find((member) => member.id === fund.holderMemberId)
		: undefined;
	const title =
		fund.cash < 0
			? t(vi.balances.fundNegative, { amount: formatMoney(-fund.cash) })
			: t(vi.balances.fundRemaining, { amount: formatMoney(fund.cash) });
	return (
		<Link
			href={`/g/${encodeURIComponent(groupId)}/fund`}
			className="flex items-center gap-4 rounded-[30px] bg-surface p-5"
		>
			<FundShape name={fund.name} size={36} />
			<div className="min-w-0 flex-1">
				<p className="break-words text-base font-black text-ink">
					{title}
					{!fund.active && (
						<span className="ml-2 text-xs font-bold text-muted">
							{vi.fund.inactiveTag}
						</span>
					)}
				</p>
				{holder && (
					<p className="mt-0.5 text-xs font-semibold text-muted">
						{t(vi.fund.holderLine, { name: holder.name })}
					</p>
				)}
			</div>
		</Link>
	);
}
