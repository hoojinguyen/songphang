"use client";
import { useBalances } from "../../lib/balances";
import { useGroup } from "../../lib/groups";
import { useMembers } from "../../lib/members";
import { formatMoney, formatSignedAmount } from "../../lib/money";
import { useMe } from "../../lib/session";
import { t, vi } from "../../messages/vi";
import {
	fundTransferCaption,
	TransferAction,
} from "../balances/TransferAction";
import { MemberShape } from "../ui/MemberShape";

export function GroupInspector({ groupId }: { groupId: string }) {
	const groupQuery = useGroup(groupId);
	const balancesQuery = useBalances(groupId);
	const membersQuery = useMembers(groupId);
	const me = useMe();
	const verified = me.data?.emailVerified ?? true;

	const group = groupQuery.data;
	const balances = balancesQuery.data;
	const members = membersQuery.data ?? [];

	if (!group || !balances) return null;

	const myBalance =
		balances.balances.find((b) => b.memberId === group.myMemberId)?.balance ??
		0;
	const isMine = group.myMemberId !== null;

	const myTransfers = balances.transfers.filter(
		(t) =>
			t.fromMemberId === group.myMemberId || t.toMemberId === group.myMemberId,
	);

	const tone =
		myBalance > 0 ? "bg-accent" : myBalance < 0 ? "bg-debt-soft" : "bg-surface";

	const caption =
		myBalance > 0
			? vi.groups.chipOwedToYou
			: myBalance < 0
				? vi.groups.chipYouOwe
				: vi.groups.chipSettled;

	return (
		<aside
			aria-label={vi.desktop.balanceSummary}
			className="sticky top-0 flex h-dvh w-[340px] shrink-0 flex-col gap-6 overflow-y-auto border-l border-sunken bg-bg p-5"
		>
			{/* Live Group Net Balance Hero */}
			<section className={`rounded-[30px] p-5 text-ink ${tone}`}>
				<p className="text-xs font-bold uppercase tracking-wider text-muted">
					{group.name}
				</p>
				<p className="mt-1 break-words text-[36px] font-black leading-tight tracking-tight">
					{formatSignedAmount(myBalance)}{" "}
					<span className="text-lg font-bold text-muted">
						{vi.common.currency}
					</span>
				</p>
				<p className="mt-1 text-xs font-bold">{caption}</p>
			</section>

			{/* Suggested Transfers for Me */}
			{isMine && myTransfers.length > 0 && (
				<section className="grid gap-3">
					<h3 className="text-xs font-bold uppercase tracking-wider text-muted">
						{vi.balances.headline}
					</h3>
					<div className="grid gap-2">
						{myTransfers.map((transfer) => {
							const from = members.find((m) => m.id === transfer.fromMemberId);
							const to = members.find((m) => m.id === transfer.toMemberId);
							if (!from || !to) return null;

							const iPay = transfer.fromMemberId === group.myMemberId;
							const caption =
								fundTransferCaption(from, to, transfer.amount) ??
								(iPay
									? t(vi.balances.youPayMember, { name: to.name })
									: t(vi.balances.memberPaysYou, { name: from.name }));

							return (
								<div
									key={`${transfer.fromMemberId}-${transfer.toMemberId}`}
									className="flex flex-col gap-2 rounded-[22px] bg-surface p-3.5"
								>
									<div className="flex items-center justify-between gap-2">
										<div className="flex items-center gap-2 min-w-0">
											<MemberShape {...(iPay ? to : from)} size={24} />
											<span className="truncate text-xs font-bold text-ink">
												{caption}
											</span>
										</div>
										<span className="shrink-0 tabular-nums text-xs font-black text-ink">
											{formatMoney(transfer.amount)}
										</span>
									</div>

									<TransferAction
										groupId={groupId}
										transfer={transfer}
										from={from}
										to={to}
										myMemberId={group.myMemberId}
										role={group.role}
										verified={verified}
										compact
									/>
								</div>
							);
						})}
					</div>
				</section>
			)}

			{/* Group Balances Summary */}
			<section className="grid gap-3">
				<h3 className="text-xs font-bold uppercase tracking-wider text-muted">
					{vi.balances.groupBalanceTitle}
				</h3>
				<div className="grid gap-1.5 rounded-[24px] bg-surface p-3.5">
					{balances.balances.map((b) => {
						const member = members.find((m) => m.id === b.memberId);
						if (!member) return null;
						const tone =
							b.balance > 0
								? "text-credit"
								: b.balance < 0
									? "text-debt"
									: "text-muted";

						return (
							<div
								key={b.memberId}
								className="flex items-center justify-between gap-2 py-1 text-xs"
							>
								<div className="flex items-center gap-2 truncate">
									<MemberShape {...member} size={18} />
									<span className="truncate font-semibold text-ink">
										{member.name}
									</span>
								</div>
								<span className={`shrink-0 tabular-nums font-bold ${tone}`}>
									{formatSignedAmount(b.balance)}
								</span>
							</div>
						);
					})}
				</div>
			</section>
		</aside>
	);
}
