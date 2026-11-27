"use client";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { AllSettled } from "../../../../components/balances/AllSettled";
import { BalanceBars } from "../../../../components/balances/BalanceBars";
import { CloseCycleModal } from "../../../../components/balances/CloseCycleModal";
import { MemberBreakdownSheet } from "../../../../components/balances/MemberBreakdownSheet";
import { OtherSettlements } from "../../../../components/balances/OtherSettlements";
import { OwnSettlementCard } from "../../../../components/balances/OwnSettlementCard";
import { PendingRequestRow } from "../../../../components/balances/PendingRequestRow";
import { SettlementCard } from "../../../../components/balances/SettlementCard";
import { SettlementCyclesView } from "../../../../components/balances/SettlementCyclesView";
import { SettlementVaultView } from "../../../../components/balances/SettlementVaultView";
import { ShareCardModal } from "../../../../components/balances/ShareCardModal";
import { FundBlock } from "../../../../components/fund/FundBlock";
import { GuestLinkModal } from "../../../../components/guest/GuestLinkModal";
import { GroupNavHeader } from "../../../../components/layout/GroupNavHeader";
import { Button } from "../../../../components/ui/Button";
import { LoadError } from "../../../../components/ui/LoadError";
import { useSnackbar } from "../../../../components/ui/Snackbar";
import { useBalances } from "../../../../lib/balances";
import { useGroup } from "../../../../lib/groups";
import { useMembers } from "../../../../lib/members";
import { formatMoney, formatSignedAmount } from "../../../../lib/money";
import { canRemindTransfer, useSendReminder } from "../../../../lib/reminders";
import { useMe } from "../../../../lib/session";
import { useSettlementCycles } from "../../../../lib/settlement-cycles";
import { usePendingSettlementRequests } from "../../../../lib/settlement-requests";
import { useTransactions } from "../../../../lib/transactions";
import { useSessionGuard } from "../../../../lib/use-session-guard";
import { t, vi } from "../../../../messages/vi";

type BalancesSubTab = "toPay" | "vault" | "cycles";

export default function BalancesPage() {
	const { groupId } = useParams<{ groupId: string }>();
	const router = useRouter();
	const [subTab, setSubTab] = useState<BalancesSubTab>("toPay");
	const [inspectedMemberId, setInspectedMemberId] = useState<string | null>(
		null,
	);
	const [closeCycleOpen, setCloseCycleOpen] = useState(false);
	const [guestLinkOpen, setGuestLinkOpen] = useState(false);
	const [shareCardOpen, setShareCardOpen] = useState(false);

	const me = useMe();
	const group = useGroup(groupId);
	const members = useMembers(groupId);
	const balances = useBalances(groupId);
	const transactions = useTransactions(groupId);
	const pendingRequests = usePendingSettlementRequests(groupId);
	const cycles = useSettlementCycles(groupId);
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
			(balances.data?.transfers.length === 0 || shareCardOpen) &&
			transactions.hasNextPage &&
			!transactions.isFetchingNextPage &&
			!transactions.isFetchNextPageError
		)
			void transactions.fetchNextPage();
	}, [
		balances.data,
		shareCardOpen,
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
	const myMemberId = group.data.myMemberId;
	const households = balances.data.households ?? [];
	const myHousehold =
		myMemberId !== null
			? households.find((h) => h.memberIds.includes(myMemberId))
			: undefined;
	const isMyFromSide = (transfer: (typeof balances.data.transfers)[number]) =>
		myMemberId !== null &&
		(transfer.fromMemberId === myMemberId ||
			Boolean(transfer.fromHousehold?.memberIds.includes(myMemberId)));
	const isMyToSide = (transfer: (typeof balances.data.transfers)[number]) =>
		myMemberId !== null &&
		(transfer.toMemberId === myMemberId ||
			Boolean(transfer.toHousehold?.memberIds.includes(myMemberId)));
	const transfers = balances.data.transfers.toSorted(
		(first, second) =>
			Number(isMyFromSide(second) || isMyToSide(second)) -
			Number(isMyFromSide(first) || isMyToSide(first)),
	);
	const own = transfers.filter(isMyFromSide);
	const otherTransfers = transfers.filter(
		(transfer) => !isMyFromSide(transfer),
	);
	const matchedIds = new Set(
		transfers.flatMap((transfer) =>
			transfer.pendingRequest ? [transfer.pendingRequest.id] : [],
		),
	);
	const unmatchedPending = (pendingRequests.data ?? []).filter(
		(request) => request.status === "pending" && !matchedIds.has(request.id),
	);
	const pendingCount = (pendingRequests.data ?? []).filter(
		(request) => request.status === "pending",
	).length;
	const closedCyclesCount = cycles.data?.cycles.length ?? 0;

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

	const individualBalance =
		balances.data.balances.find(
			(balance) => balance.memberId === group.data.myMemberId,
		)?.balance ?? 0;
	const myBalance = myHousehold ? myHousehold.netBalance : individualBalance;
	const myHouseholdRepName = myHousehold
		? (members.data.find((m) => m.id === myHousehold.representativeMemberId)
				?.name ?? "")
		: "";
	const heroTone =
		myBalance > 0
			? "bg-accent text-on-accent"
			: myBalance < 0
				? "bg-debt-soft text-ink"
				: "bg-surface text-ink";
	const heroLabel =
		myBalance > 0
			? vi.feed.owedToYou
			: myBalance < 0
				? vi.feed.youOwe
				: vi.feed.settled;

	const isArchived = group.data.archivedAt !== null;
	const canCloseCycle =
		!isArchived &&
		group.data.role !== "viewer" &&
		me.data.emailVerified &&
		cycles.data !== undefined;
	const canTriggerClose =
		(cycles.data?.currentPeriod.countedTransactionCount ?? 0) > 0;
	const canShareCard =
		transfers.length > 0 ||
		balances.data.balances.some((balance) => balance.balance !== 0);
	const loadedTransactions = transactions.data.pages.flatMap(
		(page) => page.transactions,
	);

	const subTabs: Array<{
		id: BalancesSubTab;
		label: string;
		badge?: number;
	}> = [
		{ id: "toPay", label: vi.balances.subTabs.toPay },
		{
			id: "vault",
			label: vi.balances.subTabs.vault,
			...(pendingCount > 0 ? { badge: pendingCount } : {}),
		},
		{
			id: "cycles",
			label: vi.balances.subTabs.cycles,
			...(closedCyclesCount > 0 ? { badge: closedCyclesCount } : {}),
		},
	];

	return (
		<main className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-5 px-5 pb-24 pt-6">
			<GroupNavHeader groupId={groupId} />

			<nav
				aria-label={vi.groupSegments.payments}
				className="flex gap-1.5 rounded-[20px] bg-sunken p-1"
			>
				{subTabs.map((tab) => {
					const active = subTab === tab.id;
					return (
						<button
							key={tab.id}
							type="button"
							aria-pressed={active}
							onClick={() => setSubTab(tab.id)}
							className={`flex min-h-11 flex-1 items-center justify-center gap-1.5 rounded-[16px] px-2 text-xs font-extrabold transition-colors ${
								active ? "bg-surface text-ink shadow-sm" : "text-muted"
							}`}
						>
							<span className="truncate">{tab.label}</span>
							{tab.badge !== undefined && (
								<span className="inline-flex h-4 min-w-4 items-center justify-center rounded-full bg-accent px-1 text-[10px] font-black text-on-accent">
									{tab.badge}
								</span>
							)}
						</button>
					);
				})}
			</nav>

			{subTab === "vault" ? (
				<SettlementVaultView groupId={groupId} members={members.data} />
			) : subTab === "cycles" ? (
				<SettlementCyclesView
					groupId={groupId}
					role={group.data.role}
					isArchived={isArchived}
					cyclesData={cycles.data}
					isPending={cycles.isPending}
					isError={cycles.isError}
					isFetching={cycles.isFetching}
					onRetry={() => {
						void cycles.refetch();
					}}
					onViewCycleExpenses={(cycleId) =>
						router.push(
							`/g/${encodeURIComponent(groupId)}?cycleId=${encodeURIComponent(cycleId)}`,
						)
					}
				/>
			) : (
				<>
					{group.data.myMemberId !== null && (
						<section className={`rounded-[30px] p-5 ${heroTone}`}>
							<p className="text-xs font-bold opacity-80">
								{myHousehold ? `${myHousehold.name} · ${heroLabel}` : heroLabel}
							</p>
							<p className="mt-1 tabular-nums text-[36px] font-black leading-tight tracking-tight">
								{formatMoney(Math.abs(myBalance))}
							</p>
							{myHousehold && (
								<p className="mt-1.5 text-xs font-semibold opacity-80">
									{t(vi.households.personalShareTemplate, {
										amount: `${formatSignedAmount(individualBalance)} ${vi.common.currency}`,
									})}{" "}
									·{" "}
									{t(vi.households.settledThroughTemplate, {
										name: myHouseholdRepName,
									})}
								</p>
							)}
						</section>
					)}

					{(canShareCard || canCloseCycle || group.data.role !== "viewer") && (
						<div className="grid gap-1.5">
							<div className="flex flex-wrap gap-2">
								{canShareCard && (
									<Button
										variant="surface"
										allowOffline
										onClick={() => setShareCardOpen(true)}
										className="flex-1 text-xs"
									>
										{vi.shareCard.openAction}
									</Button>
								)}
								{group.data.role !== "viewer" && (
									<Button
										variant="surface"
										allowOffline
										onClick={() => setGuestLinkOpen(true)}
										className="flex-1 text-xs"
									>
										{vi.guestLink.title}
									</Button>
								)}
								{canCloseCycle && (
									<Button
										variant="surface"
										disabled={!canTriggerClose}
										onClick={() => setCloseCycleOpen(true)}
										className="flex-1 text-xs"
									>
										{vi.cycles.closeAction}
									</Button>
								)}
							</div>
							{canCloseCycle && !canTriggerClose && (
								<p className="text-center text-xs font-semibold text-muted">
									{vi.cycles.emptyPeriodError}
								</p>
							)}
						</div>
					)}

					{balances.data.fund && (
						<FundBlock
							groupId={groupId}
							fund={balances.data.fund}
							members={members.data}
						/>
					)}

					{!hasTransactions ? (
						<div className="my-auto py-12">
							<h2 className="text-[34px] font-black">
								{vi.balances.emptyTitle}
							</h2>
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
											count: String(
												own.length > 0 ? own.length : transfers.length,
											),
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
											onInspectMember={setInspectedMemberId}
										/>
									))}
									<OtherSettlements
										groupId={groupId}
										transfers={otherTransfers}
										members={members.data}
										myMemberId={group.data.myMemberId}
										role={group.data.role}
										verified={me.data.emailVerified}
										onRemindNotice={(text) => showNotice({ text })}
										onInspectMember={setInspectedMemberId}
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
										onInspectMember={setInspectedMemberId}
									/>
								))
							)}

							<BalanceBars
								balances={balances.data.balances}
								households={households}
								members={members.data}
								onInspectMember={setInspectedMemberId}
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
								const fromHousehold = households.find(
									(h) => h.representativeMemberId === from.id,
								);
								const canCancel =
									request.createdBy?.id === me.data.id ||
									group.data.myMemberId === from.id ||
									(group.data.myMemberId !== null &&
										Boolean(
											fromHousehold?.memberIds.includes(group.data.myMemberId),
										));
								return (
									<PendingRequestRow
										key={request.id}
										groupId={groupId}
										request={{
											id: request.id,
											amount: request.amount,
											createdByMe: request.createdBy?.id === me.data.id,
											channel: request.channel ?? null,
											note: request.note ?? null,
											proofAttachmentId: request.proofAttachment?.id ?? null,
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
				</>
			)}

			<MemberBreakdownSheet
				open={inspectedMemberId !== null}
				memberId={inspectedMemberId}
				groupId={groupId}
				transfers={transfers}
				members={members.data}
				onClose={() => setInspectedMemberId(null)}
			/>

			{cycles.data && (
				<CloseCycleModal
					open={closeCycleOpen}
					groupId={groupId}
					nextCycleNumber={(cycles.data.cycles[0]?.cycleNumber ?? 0) + 1}
					currentPeriod={cycles.data.currentPeriod}
					onClose={() => setCloseCycleOpen(false)}
				/>
			)}
			{group.data.role !== "viewer" && (
				<GuestLinkModal
					open={guestLinkOpen}
					groupId={groupId}
					isArchived={isArchived}
					onClose={() => setGuestLinkOpen(false)}
				/>
			)}
			<ShareCardModal
				open={shareCardOpen}
				groupId={groupId}
				groupName={group.data.name}
				role={group.data.role}
				balances={balances.data}
				members={members.data}
				transactions={loadedTransactions}
				hasMoreTransactions={transactions.hasNextPage}
				cycles={cycles.data?.cycles ?? []}
				currentPeriod={cycles.data?.currentPeriod}
				onClose={() => setShareCardOpen(false)}
			/>
		</main>
	);
}
