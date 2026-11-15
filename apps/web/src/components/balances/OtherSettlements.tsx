import type { BalancesResponse, MemberDto } from "@songphang/contract";
import Link from "next/link";
import { settlementHref } from "../../lib/balances";
import { formatMoney } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { MemberShape } from "../ui/MemberShape";
export function OtherSettlements({
	groupId,
	transfers,
	members,
	canEdit,
}: {
	groupId: string;
	transfers: BalancesResponse["transfers"];
	members: MemberDto[];
	canEdit: boolean;
}) {
	if (transfers.length === 0) return null;
	return (
		<section className="grid gap-3 rounded-[30px] bg-surface p-5">
			<h2 className="font-extrabold">{vi.balances.othersTitle}</h2>
			{transfers.map((transfer) => {
				const from = members.find((m) => m.id === transfer.fromMemberId);
				const to = members.find((m) => m.id === transfer.toMemberId);
				if (!from || !to) return null;
				return (
					<div
						key={`${from.id}-${to.id}`}
						className="flex flex-wrap items-center gap-2"
					>
						<MemberShape {...from} size={28} />
						<p className="min-w-0 flex-1 text-xs">
							{t(vi.balances.memberPaysMember, {
								from: from.name,
								to: to.name,
							})}
						</p>
						<span className="text-sm font-extrabold">
							{formatMoney(transfer.amount)}
						</span>
						{canEdit && (
							<Link
								href={settlementHref(groupId, transfer)}
								className="flex min-h-11 items-center rounded-pill bg-sunken px-3 text-xs font-bold"
							>
								{vi.balances.record}
							</Link>
						)}
					</div>
				);
			})}
		</section>
	);
}
