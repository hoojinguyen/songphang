import type { BalancesResponse, MemberDto } from "@songphang/contract";
import Link from "next/link";
import { settlementHref } from "../../lib/balances";
import { formatAmount } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { MemberShape } from "../ui/MemberShape";
export function OwnSettlementCard({
	groupId,
	transfer,
	members,
	canEdit,
}: {
	groupId: string;
	transfer: BalancesResponse["transfers"][number];
	members: MemberDto[];
	canEdit: boolean;
}) {
	const to = members.find((member) => member.id === transfer.toMemberId);
	if (!to) return null;
	return (
		<section className="grid justify-items-center gap-3 rounded-[40px] bg-surface p-5">
			<MemberShape {...to} size={84} />
			<p className="text-[13px]">
				{t(vi.balances.youPayMember, { name: to.name })}
			</p>
			<p className="text-[40px] font-black">{formatAmount(transfer.amount)}</p>
			{canEdit && (
				<Link
					href={settlementHref(groupId, transfer)}
					className="flex min-h-[60px] w-full items-center justify-center rounded-[30px] bg-accent font-extrabold"
				>
					{vi.balances.paid}
				</Link>
			)}
		</section>
	);
}
