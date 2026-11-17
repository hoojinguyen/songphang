import type { BalancesResponse, MemberDto } from "@songphang/contract";
import { formatAmount } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { MemberShape } from "../ui/MemberShape";
import { fundTransferCaption, TransferAction } from "./TransferAction";
export function OwnSettlementCard({
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
	const caption =
		fundTransferCaption(from, to, transfer.amount) ??
		t(vi.balances.youPayMember, { name: to.name });
	return (
		<section className="grid justify-items-center gap-3 rounded-[40px] bg-surface p-5">
			<MemberShape {...to} size={84} />
			<p className="text-[13px]">{caption}</p>
			<p className="text-[40px] font-black">{formatAmount(transfer.amount)}</p>
			<TransferAction
				groupId={groupId}
				transfer={transfer}
				from={from}
				to={to}
				myMemberId={myMemberId}
				role={role}
				verified={verified}
			/>
		</section>
	);
}
