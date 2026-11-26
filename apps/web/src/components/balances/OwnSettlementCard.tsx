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
	onInspectMember,
}: {
	groupId: string;
	transfer: BalancesResponse["transfers"][number];
	members: MemberDto[];
	myMemberId: string | null;
	role: "owner" | "editor" | "viewer";
	verified: boolean;
	onInspectMember?: (memberId: string) => void;
}) {
	const from = members.find((member) => member.id === transfer.fromMemberId);
	const to = members.find((member) => member.id === transfer.toMemberId);
	if (!from || !to) return null;
	const caption =
		fundTransferCaption(from, to, transfer.amount) ??
		t(vi.balances.youPayMember, { name: to.name });
	const householdLine = [
		transfer.fromHousehold
			? t(vi.households.representativeBadge, {
					name: transfer.fromHousehold.name,
				})
			: null,
		transfer.toHousehold
			? t(vi.households.representativeBadge, {
					name: transfer.toHousehold.name,
				})
			: null,
	]
		.filter(Boolean)
		.join(" → ");
	return (
		<section className="grid justify-items-center gap-3 rounded-[40px] bg-surface p-5">
			<MemberShape {...to} size={84} />
			<p className="text-[13px]">{caption}</p>
			{householdLine && (
				<p className="text-xs font-bold text-muted">{householdLine}</p>
			)}
			<p className="tabular-nums text-[40px] font-black">
				{formatAmount(transfer.amount)}
			</p>
			{onInspectMember && from.kind === "person" && (
				<button
					type="button"
					onClick={() => onInspectMember(from.id)}
					className="inline-flex min-h-11 items-center text-xs font-bold text-muted underline hover:text-ink"
				>
					{vi.breakdown.viewAction}
				</button>
			)}
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
