import type { BalancesResponse, MemberDto } from "@songphang/contract";
import { settlementHref } from "../../lib/balances";
import { formatAmount } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { MemberShape } from "../ui/MemberShape";
import { OnlineLink } from "../ui/OnlineLink";
export function SettlementCard({
	groupId,
	canEdit,
	transfer,
	members,
	myMemberId,
}: {
	groupId: string;
	canEdit: boolean;
	transfer: BalancesResponse["transfers"][number];
	members: MemberDto[];
	myMemberId: string | null;
}) {
	const from = members.find((member) => member.id === transfer.fromMemberId);
	const to = members.find((member) => member.id === transfer.toMemberId);
	if (!from || !to) return null;
	const other = transfer.fromMemberId === myMemberId ? to : from;
	const caption =
		transfer.fromMemberId === myMemberId
			? t(vi.balances.youPayMember, { name: to.name })
			: transfer.toMemberId === myMemberId
				? t(vi.balances.memberPaysYou, { name: from.name })
				: t(vi.balances.memberPaysMember, { from: from.name, to: to.name });
	return (
		<div className="settlement-card grid gap-4 rounded-[36px] bg-surface p-5">
			<div className="flex items-center gap-4">
				<MemberShape {...other} size={76} />
				<div className="min-w-0">
					<p className="break-words text-[13px] font-semibold text-muted">
						{caption}
					</p>
					<p className="break-words text-[26px] font-black">
						{formatAmount(transfer.amount)}
					</p>
				</div>
			</div>
			{canEdit && (
				<OnlineLink
					href={settlementHref(groupId, transfer)}
					className="flex min-h-[60px] items-center justify-center rounded-[30px] bg-accent font-extrabold"
				>
					{transfer.toMemberId === myMemberId
						? vi.balances.received
						: vi.balances.record}
				</OnlineLink>
			)}
		</div>
	);
}
