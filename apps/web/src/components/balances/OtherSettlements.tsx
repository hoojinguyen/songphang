import type { BalancesResponse, MemberDto } from "@songphang/contract";
import { formatMoney } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { MemberShape } from "../ui/MemberShape";
import { fundTransferCaption, TransferAction } from "./TransferAction";
export function OtherSettlements({
	groupId,
	transfers,
	members,
	myMemberId,
	role,
	verified,
	onRemindNotice,
	onInspectMember,
}: {
	groupId: string;
	transfers: BalancesResponse["transfers"];
	members: MemberDto[];
	myMemberId: string | null;
	role: "owner" | "editor" | "viewer";
	verified: boolean;
	onRemindNotice?: (message: string) => void;
	onInspectMember?: (memberId: string) => void;
}) {
	if (transfers.length === 0) return null;
	return (
		<section className="grid gap-3 rounded-[30px] bg-surface p-5">
			<h2 className="font-extrabold">{vi.balances.othersTitle}</h2>
			{transfers.map((transfer) => {
				const from = members.find((m) => m.id === transfer.fromMemberId);
				const to = members.find((m) => m.id === transfer.toMemberId);
				if (!from || !to) return null;
				const fundCaption = fundTransferCaption(from, to, transfer.amount);
				return (
					<div
						key={`${from.id}-${to.id}`}
						className="flex flex-wrap items-center gap-2"
					>
						<MemberShape {...from} size={28} />
						<div className="min-w-0 flex-1">
							<p className="text-xs">
								{fundCaption ??
									t(vi.balances.memberPaysMember, {
										from: from.name,
										to: to.name,
									})}
							</p>
							{onInspectMember && from.kind === "person" && (
								<button
									type="button"
									onClick={() => onInspectMember(from.id)}
									className="text-[11px] font-bold text-muted underline hover:text-ink"
								>
									{vi.breakdown.viewAction}
								</button>
							)}
						</div>
						{!fundCaption && (
							<span className="tabular-nums text-sm font-extrabold">
								{formatMoney(transfer.amount)}
							</span>
						)}
						<TransferAction
							groupId={groupId}
							transfer={transfer}
							from={from}
							to={to}
							myMemberId={myMemberId}
							role={role}
							verified={verified}
							compact
							{...(onRemindNotice ? { onRemindNotice } : {})}
						/>
					</div>
				);
			})}
		</section>
	);
}
