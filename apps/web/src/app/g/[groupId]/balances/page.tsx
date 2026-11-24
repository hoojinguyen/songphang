"use client";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useEffect } from "react";
import { AllSettled } from "../../../../components/balances/AllSettled";
import { BalanceBars } from "../../../../components/balances/BalanceBars";
import { OtherSettlements } from "../../../../components/balances/OtherSettlements";
import { OwnSettlementCard } from "../../../../components/balances/OwnSettlementCard";
import { PendingRequestRow } from "../../../../components/balances/PendingRequestRow";
import { SettlementCard } from "../../../../components/balances/SettlementCard";
import { FundBlock } from "../../../../components/fund/FundBlock";
import { GroupNavHeader } from "../../../../components/layout/GroupNavHeader";
import { Button } from "../../../../components/ui/Button";
import { LoadError } from "../../../../components/ui/LoadError";
import { useSnackbar } from "../../../../components/ui/Snackbar";
import { useBalances } from "../../../../lib/balances";
import { useGroup } from "../../../../lib/groups";
import { useMembers } from "../../../../lib/members";
import { canRemindTransfer, useSendReminder } from "../../../../lib/reminders";
import { useMe } from "../../../../lib/session";
import { usePendingSettlementRequests } from "../../../../lib/settlement-requests";
import { useTransactions } from "../../../../lib/transactions";
import { useSessionGuard } from "../../../../lib/use-session-guard";
import { t, vi } from "../../../../messages/vi";
export default function BalancesPage() {
	const { groupId } = useParams<{ groupId: string }>();
	const me = useMe();
	const group = useGroup(groupId);
	const members = useMembers(groupId);
	const balances = useBalances(groupId);
	const transactions = useTransactions(groupId);
	const pendingRequests = usePendingSettlementRequests(groupId);
	const sendAllReminders = useSendReminder(groupId);
	const showNotice = useSnackbar();
	const error =
		group.error ??
		members.error ??
		balances.error ??
		transactions.error ??
		me.error;
	useEffect(() => {
		if (
			balances.data?.transfers.length === 0 &&
			transactions.hasNextPage &&
			!transactions.isFetchingNextPage &&
			!transactions.isFetchNextPageError
		)
			void transactions.fetchNextPage();
	}, [
		balances.data,
		transactions.hasNextPage,
		transactions.isFetchingNextPage,
		transactions.isFetchNextPageError,
		transactions.fetchNextPage,
	]);
	useSessionGuard(error);
	if (error?.status === 404)
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center gap-4 px-5 text-center">
				<p>{vi.common.groupNotFound}</p>
				<Link href="/" className="flex min-h-11 items-center justify-center">
					{vi.common.backToGroups}
				</Link>
			</main>
		);
	if (
		me.isPending ||
		group.isPending ||
		members.isPending ||
		balances.isPending ||
		transactions.isPending ||
		error?.status === 401
	)
		return (
			<main
				aria-busy="true"
				className="mx-auto grid min-h-dvh max-w-[430px] gap-5 p-5"
			>
				<div className="h-12 rounded-card bg-sunken" />
				<div className="h-40 rounded-card bg-sunken" />
				<div className="h-64 rounded-card bg-sunken" />
			</main>
		);
	if (
		(me.isError && !me.data) ||
		(group.isError && !group.data) ||
		(members.isError && !members.data) ||
		(balances.isError && !balances.data) ||
		transactions.isError
	)
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center px-5">
				<LoadError
					onRetry={() => {
						void me.refetch();
						void group.refetch();
						void members.refetch();
						void balances.refetch();
						void transactions.refetch();
					}}
					isRetrying={
						group.isFetching ||
						members.isFetching ||
						balances.isFetching ||
						transactions.isFetching
					}
				/>
			</main>
		);
	const hasTransactions =
		(transactions.data.pages[0]?.transactions.length ?? 0) > 0;
	const transfers = balances.data.transfers.toSorted(
		(first, second) =>
			Number(
				second.fromMemberId === group.data.myMemberId ||
					second.toMemberId === group.data.myMemberId,
			) -
			Number(
				first.fromMemberId === group.data.myMemberId ||
					first.toMemberId === group.data.myMemberId,
			),
	);
	const own = transfers.filter(
		(transfer) => transfer.fromMemberId === group.data.myMemberId,
	);
	const matchedIds = new Set(
		transfers.flatMap((transfer) =>
			transfer.pendingRequest ? [transfer.pendingRequest.id] : [],
		),
	);
	const unmatchedPending = (pendingRequests.data ?? []).filter(
		(request) => request.status === "pending" && !matchedIds.has(request.id),
	);
	const remindableCount = transfers.filter((transfer) => {
		const from = members.data.find((m) => m.id === transfer.fromMemberId);
		const to = members.data.find((m) => m.id === transfer.toMemberId);
		if (!from || !to) return false;
		return canRemindTransfer({
			transfer,
			from,
			to,
			myMemberId: group.data.myMemberId,
			role: group.data.role,
			verified: me.data.emailVerified,
		});
	}).length;
	const handleRemindAll = async () => {
		try {
			const res = await sendAllReminders.mutateAsync({ all: true });
			showNotice({
				text: t(vi.reminders.remindedMany, {
					count: String(res.reminded.length),
				}),
			});
		} catch {
			showNotice({ text: vi.common.saveError });
		}
	};

	return (
		<main className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-5 px-5 pb-24 pt-6">
			<GroupNavHeader groupId={groupId} />
			{balances.data.fund && (
				<FundBlock
					groupId={groupId}
					fund={balances.data.fund}
					members={members.data}
				/>
			)}
			{!hasTransactions ? (
				<div className="my-auto py-12">
					<h2 className="text-[34px] font-black">{vi.balances.emptyTitle}</h2>
					<p className="mt-3 text-sm text-muted">{vi.balances.emptyHint}</p>
				</div>
			) : transfers.length === 0 ? (
				<AllSettled
					recorded={transactions.data.pages
						.flatMap((page) => page.transactions)
						.filter((transaction) => transaction.type === "transfer")}
					groupId={groupId}
					members={members.data}
					myMemberId={group.data.myMemberId}
				/>
			) : (
				<>
					<div>
						<h2 className="text-[34px] font-black">
							{t(
								own.length > 0
									? vi.balances.youPayHeadline
									: vi.balances.headline,
								{
									count: String(own.length > 0 ? own.length : transfers.length),
								},
							)}
						</h2>
						<p className="mt-2 text-sm text-muted">
							{own.length > 0
								? vi.balances.youPayHint
								: balances.data.minimized
									? vi.balances.collectHint
									: vi.balances.pairwiseHint}
						</p>
						{remindableCount >= 2 && (
							<Button
								variant="surface"
								disabled={sendAllReminders.isPending}
								onClick={() => {
									void handleRemindAll();
								}}
								className="mt-3"
							>
								{vi.reminders.remindAll}
							</Button>
						)}
					</div>
					{own.length > 0 ? (
						<>
							{own.map((transfer) => (
								<OwnSettlementCard
									key={`${transfer.fromMemberId}-${transfer.toMemberId}`}
									groupId={groupId}
									transfer={transfer}
									members={members.data}
									myMemberId={group.data.myMemberId}
									role={group.data.role}
									verified={me.data.emailVerified}
								/>
							))}
							<OtherSettlements
								groupId={groupId}
								transfers={transfers.filter(
									(transfer) => transfer.fromMemberId !== group.data.myMemberId,
								)}
								members={members.data}
								myMemberId={group.data.myMemberId}
								role={group.data.role}
								verified={me.data.emailVerified}
								onRemindNotice={(text) => showNotice({ text })}
							/>
						</>
					) : (
						transfers.map((transfer) => (
							<SettlementCard
								key={`${transfer.fromMemberId}-${transfer.toMemberId}`}
								groupId={groupId}
								transfer={transfer}
								members={members.data}
								myMemberId={group.data.myMemberId}
								role={group.data.role}
								verified={me.data.emailVerified}
								onRemindNotice={(text) => showNotice({ text })}
							/>
						))
					)}

					<BalanceBars
						balances={balances.data.balances}
						members={members.data}
					/>
				</>
			)}
			{unmatchedPending.length > 0 && (
				<section className="grid gap-3 rounded-[30px] bg-surface p-5">
					{unmatchedPending.map((request) => {
						const from = members.data.find(
							(member) => member.id === request.fromMemberId,
						);
						const to = members.data.find(
							(member) => member.id === request.toMemberId,
						);
						if (!from || !to) return null;
						const canResolve =
							group.data.role === "owner" ||
							group.data.myMemberId === to.id ||
							(group.data.role === "editor" && !to.claimed);
						const canCancel =
							request.createdBy?.id === me.data.id ||
							group.data.myMemberId === from.id;
						return (
							<PendingRequestRow
								key={request.id}
								groupId={groupId}
								request={{
									id: request.id,
									amount: request.amount,
									createdByMe: request.createdBy?.id === me.data.id,
								}}
								fromName={from.name}
								toName={to.name}
								canResolve={canResolve}
								canCancel={canCancel}
								verified={me.data.emailVerified}
							/>
						);
					})}
				</section>
			)}
		</main>
	);
}
