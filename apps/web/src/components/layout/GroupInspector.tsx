"use client";
import Link from "next/link";
import { payHref, settlementHref, useBalances } from "../../lib/balances";
import { useGroup } from "../../lib/groups";
import { useMembers } from "../../lib/members";
import { formatMoney, formatSignedAmount } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { MemberShape } from "../ui/MemberShape";

export function GroupInspector({ groupId }: { groupId: string }) {
	const groupQuery = useGroup(groupId);
	const balancesQuery = useBalances(groupId);
	const membersQuery = useMembers(groupId);

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

							return (
								<div
									key={`${transfer.fromMemberId}-${transfer.toMemberId}`}
									className="flex flex-col gap-2 rounded-[22px] bg-surface p-3.5"
								>
									<div className="flex items-center justify-between gap-2">
										<div className="flex items-center gap-2">
											<MemberShape {...(iPay ? to : from)} size={24} />
											<span className="text-xs font-bold text-ink">
												{iPay
													? t(vi.balances.youPayMember, { name: to.name })
													: t(vi.balances.memberPaysYou, { name: from.name })}
											</span>
										</div>
										<span className="tabular-nums text-xs font-black text-ink">
											{formatMoney(transfer.amount)}
										</span>
									</div>

									<div className="flex gap-2">
										{iPay ? (
											<>
												<Link
													href={payHref(groupId, transfer)}
													className="flex h-9 flex-1 items-center justify-center rounded-pill bg-ink text-xs font-bold text-on-ink transition-opacity hover:opacity-90"
												>
													{vi.feed.pay}
												</Link>
												<Link
													href={settlementHref(groupId, transfer)}
													className="flex h-9 items-center justify-center rounded-pill bg-sunken px-3 text-xs font-bold text-ink transition-colors hover:bg-surface-raised"
												>
													{vi.pay.reportedButton}
												</Link>
											</>
										) : (
											<Link
												href={settlementHref(groupId, transfer)}
												className="flex h-9 flex-1 items-center justify-center rounded-pill bg-ink text-xs font-bold text-on-ink transition-opacity hover:opacity-90"
											>
												{vi.balances.received}
											</Link>
										)}
									</div>
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
