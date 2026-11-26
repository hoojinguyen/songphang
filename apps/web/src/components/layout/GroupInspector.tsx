"use client";
import type { MemberDto } from "@songphang/contract";
import Link from "next/link";
import { useState } from "react";
import { useBalances } from "../../lib/balances";
import { useGroup } from "../../lib/groups";
import { useMembers } from "../../lib/members";
import { formatMoney, formatSignedAmount } from "../../lib/money";
import { useMe } from "../../lib/session";
import { useTransaction } from "../../lib/transaction-changes";
import { dayLabel } from "../../lib/transactions";
import { t, vi } from "../../messages/vi";
import { MemberBreakdownSheet } from "../balances/MemberBreakdownSheet";
import {
	fundTransferCaption,
	TransferAction,
} from "../balances/TransferAction";
import { Icon } from "../ui/Icon";
import { LoadError } from "../ui/LoadError";
import { MemberShape } from "../ui/MemberShape";
import { useSnackbar } from "../ui/Snackbar";
import { useDesktopInspector } from "./DesktopInspectorContext";

function InspectorTransactionPreview({
	groupId,
	transactionId,
	members,
	onClose,
}: {
	groupId: string;
	transactionId: string;
	members: MemberDto[];
	onClose: () => void;
}) {
	const tx = useTransaction(groupId, transactionId);

	return (
		<aside
			aria-label={vi.feed.view}
			className="sticky top-0 flex h-dvh w-[340px] shrink-0 flex-col gap-4 overflow-y-auto border-l border-sunken bg-bg p-5"
		>
			<div className="flex items-center justify-between gap-2">
				<h3 className="text-xs font-bold uppercase tracking-wider text-muted">
					{vi.feed.view}
				</h3>
				<button
					type="button"
					onClick={onClose}
					aria-label={vi.common.cancel}
					className="flex size-9 items-center justify-center rounded-full bg-surface text-ink hover:bg-sunken"
				>
					<Icon name="close" size={16} />
				</button>
			</div>

			{tx.isPending ? (
				<div aria-busy="true" className="h-56 rounded-[24px] bg-sunken" />
			) : tx.isError ? (
				<LoadError
					onRetry={() => {
						void tx.refetch();
					}}
					isRetrying={tx.isFetching}
				/>
			) : (
				<div className="grid gap-4 rounded-[28px] bg-surface p-5">
					<div>
						<p className="text-xs font-semibold text-muted">
							{dayLabel(tx.data.occurredAt, new Date())}
						</p>
						<h4 className="mt-1 break-words text-lg font-black text-ink">
							{tx.data.description}
						</h4>
						<p className="mt-2 tabular-nums text-[28px] font-black text-ink">
							{formatMoney(tx.data.amount)}
						</p>
					</div>

					<div className="grid gap-1.5 border-t border-sunken pt-3">
						<p className="text-[11px] font-bold uppercase tracking-wider text-muted">
							{vi.expenseForm.payerTitle}
						</p>
						{tx.data.payers.map((payer) => {
							const member = members.find((m) => m.id === payer.memberId);
							return (
								<div
									key={payer.memberId}
									className="flex items-center justify-between text-xs"
								>
									<span className="font-semibold text-ink">
										{member?.name ?? vi.common.you}
									</span>
									<span className="tabular-nums font-bold text-ink">
										{formatMoney(payer.amount)}
									</span>
								</div>
							);
						})}
					</div>

					<div className="grid gap-1.5 border-t border-sunken pt-3">
						<p className="text-[11px] font-bold uppercase tracking-wider text-muted">
							{vi.expenseForm.sharersTitle}
						</p>
						{tx.data.shares.map((share) => {
							const member = members.find((m) => m.id === share.memberId);
							return (
								<div
									key={share.memberId}
									className="flex items-center justify-between text-xs"
								>
									<span className="font-semibold text-ink">
										{member?.name ?? vi.common.you}
									</span>
									<span className="tabular-nums font-bold text-ink">
										{formatMoney(share.amount)}
									</span>
								</div>
							);
						})}
					</div>

					<Link
						href={`/g/${encodeURIComponent(groupId)}/tx/${encodeURIComponent(transactionId)}/view`}
						className="flex min-h-11 items-center justify-center rounded-pill bg-ink px-4 text-xs font-bold text-on-ink"
					>
						{vi.feed.view}
					</Link>
				</div>
			)}
		</aside>
	);
}

export function GroupInspector({ groupId }: { groupId: string }) {
	const groupQuery = useGroup(groupId);
	const balancesQuery = useBalances(groupId);
	const membersQuery = useMembers(groupId);
	const me = useMe();
	const showNotice = useSnackbar();
	const { selectedTx, clearTx } = useDesktopInspector();
	const [inspectedMemberId, setInspectedMemberId] = useState<string | null>(
		null,
	);
	const verified = me.data?.emailVerified ?? true;

	const group = groupQuery.data;
	const balances = balancesQuery.data;
	const members = membersQuery.data ?? [];

	if (selectedTx?.groupId === groupId) {
		return (
			<InspectorTransactionPreview
				groupId={groupId}
				transactionId={selectedTx.transactionId}
				members={members}
				onClose={clearTx}
			/>
		);
	}

	if (!group || !balances) return null;

	const myBalance =
		balances.balances.find((b) => b.memberId === group.myMemberId)?.balance ??
		0;
	const isMine = group.myMemberId !== null;

	const myTransfers = balances.transfers.filter(
		(t) =>
			t.fromMemberId === group.myMemberId || t.toMemberId === group.myMemberId,
	);

	const isPositive = myBalance > 0;
	const tone = isPositive
		? "bg-accent text-on-accent"
		: myBalance < 0
			? "bg-debt-soft text-ink"
			: "bg-surface text-ink";
	const subTone = isPositive ? "text-on-accent/75" : "text-muted";

	const caption = isPositive
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
			<section className={`rounded-[30px] p-5 ${tone}`}>
				<p className={`text-xs font-bold uppercase tracking-wider ${subTone}`}>
					{group.name}
				</p>
				<p className="mt-1 break-words text-[36px] font-black leading-tight tracking-tight">
					{formatSignedAmount(myBalance)}{" "}
					<span className={`text-lg font-bold ${subTone}`}>
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
							const fundCaption = fundTransferCaption(
								from,
								to,
								transfer.amount,
							);
							const caption =
								fundCaption ??
								(iPay
									? t(vi.balances.youPayMember, { name: to.name })
									: t(vi.balances.memberPaysYou, { name: from.name }));

							const displayedMember = iPay ? to : from;
							const canInspectDisplayed =
								displayedMember.kind === "person" && fundCaption === null;

							return (
								<div
									key={`${transfer.fromMemberId}-${transfer.toMemberId}`}
									className="flex flex-col gap-2 rounded-[22px] bg-surface p-3.5"
								>
									<div className="flex items-center justify-between gap-2">
										{canInspectDisplayed ? (
											<button
												type="button"
												onClick={() => setInspectedMemberId(displayedMember.id)}
												className="flex min-w-0 items-center gap-2 text-left hover:underline"
											>
												<MemberShape {...displayedMember} size={24} />
												<span className="truncate text-xs font-bold text-ink">
													{caption}
												</span>
											</button>
										) : (
											<div className="flex min-w-0 items-center gap-2 text-left">
												<MemberShape {...displayedMember} size={24} />
												<span className="truncate text-xs font-bold text-ink">
													{caption}
												</span>
											</div>
										)}
										{fundCaption === null && (
											<span className="shrink-0 tabular-nums text-xs font-black text-ink">
												{formatMoney(transfer.amount)}
											</span>
										)}
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
										onRemindNotice={(text) => showNotice({ text })}
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
							<button
								key={b.memberId}
								type="button"
								onClick={() =>
									member.kind === "person"
										? setInspectedMemberId(member.id)
										: undefined
								}
								className="flex min-h-11 w-full items-center justify-between gap-2 rounded-[12px] px-1 py-1 text-left text-xs hover:bg-sunken/50"
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
							</button>
						);
					})}
				</div>
			</section>
			<MemberBreakdownSheet
				open={inspectedMemberId !== null}
				memberId={inspectedMemberId}
				groupId={groupId}
				transfers={balances.transfers}
				members={members}
				onClose={() => setInspectedMemberId(null)}
			/>
		</aside>
	);
}
