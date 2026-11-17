import type { BalancesResponse, MemberDto } from "@songphang/contract";
import { formatAmount } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { MemberShape } from "../ui/MemberShape";
import { fundTransferCaption, TransferAction } from "./TransferAction";
export function SettlementCard({
	groupId,
	transfer,
	members,
	myMemberId,
	role,
	verified,
}: {
	groupId: string;
	transfer: BalancesResponse["transfers"][number];
	members: MemberDto[];
	myMemberId: string | null;
	role: "owner" | "editor" | "viewer";
	verified: boolean;
}) {
	const from = members.find((member) => member.id === transfer.fromMemberId);
	const to = members.find((member) => member.id === transfer.toMemberId);
	if (!from || !to) return null;
	const other = transfer.fromMemberId === myMemberId ? to : from;
	const caption =
		fundTransferCaption(from, to, transfer.amount) ??
		(transfer.fromMemberId === myMemberId
			? t(vi.balances.youPayMember, { name: to.name })
			: transfer.toMemberId === myMemberId
				? t(vi.balances.memberPaysYou, { name: from.name })
				: t(vi.balances.memberPaysMember, { from: from.name, to: to.name }));
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
			<TransferAction
				groupId={groupId}
				transfer={transfer}
				from={from}
				to={to}
				myMemberId={myMemberId}
				role={role}
				verified={verified}
			/>
		</div>
	);
}
