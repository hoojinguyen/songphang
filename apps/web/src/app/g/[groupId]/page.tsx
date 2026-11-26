"use client";
import Link from "next/link";
import { useParams, useRouter, useSearchParams } from "next/navigation";
import { Suspense, useCallback, useMemo, useState } from "react";
import { BalanceBlock } from "../../../components/feed/BalanceBlock";
import { BudgetBanner } from "../../../components/feed/BudgetBanner";
import { CycleFilterChip } from "../../../components/feed/CycleFilterChip";
import { EmptyStream } from "../../../components/feed/EmptyStream";
import { EntryBar } from "../../../components/feed/EntryBar";
import { ExpenseStream } from "../../../components/feed/ExpenseStream";
import { FilterChips } from "../../../components/feed/FilterChips";
import { FilterSheet } from "../../../components/feed/FilterSheet";
import { StreamSearchBar } from "../../../components/feed/StreamSearchBar";
import { GroupNavHeader } from "../../../components/layout/GroupNavHeader";
import { LoadError } from "../../../components/ui/LoadError";
import { VerifyEmailBanner } from "../../../components/ui/VerifyEmailBanner";
import { useBalances } from "../../../lib/balances";
import { useBudget } from "../../../lib/budget";
import { useCategories } from "../../../lib/categories";
import { useGroup } from "../../../lib/groups";
import { useMembers } from "../../../lib/members";
import {
	formatCalendarDateVN,
	useRecurringExpenses,
} from "../../../lib/recurring-expenses";
import { useMe } from "../../../lib/session";
import { useSettlementCycles } from "../../../lib/settlement-cycles";
import {
	buildFilterQueryString,
	hasActiveFilters,
	readTransactionFilters,
	type TransactionFilters,
	useTransactions,
} from "../../../lib/transactions";
import { useSessionGuard } from "../../../lib/use-session-guard";
import { t, vi } from "../../../messages/vi";

function GroupScreen() {
	const { groupId } = useParams<{ groupId: string }>();
	const searchParams = useSearchParams();
	const paramsKey = searchParams.toString();
	const router = useRouter();
	const filters = useMemo(
		() => readTransactionFilters(new URLSearchParams(paramsKey)),
		[paramsKey],
	);
	const rawCycleParam = searchParams.get("cycleId");
	const filtersActive = hasActiveFilters(filters);
	const [atTop, setAtTop] = useState(true);
	const [sheetOpen, setSheetOpen] = useState(false);
	const me = useMe();
	const group = useGroup(groupId);
	const members = useMembers(groupId);
	const categories = useCategories(groupId);
	const balances = useBalances(groupId);
	const budget = useBudget(groupId);
	const cycles = useSettlementCycles(groupId);
	const recurringQuery = useRecurringExpenses(groupId);
	const hasClosedCycles = (cycles.data?.cycles.length ?? 0) > 0;
	const knownCycleIds = new Set(cycles.data?.cycles.map((cycle) => cycle.id));
	const requestedCycleId = filters.cycleId ?? "current";
	const selectedCycleId: "current" | string | undefined = hasClosedCycles
		? rawCycleParam === "all"
			? undefined
			: requestedCycleId === "current" || knownCycleIds.has(requestedCycleId)
				? requestedCycleId
				: "current"
		: undefined;
	const effectiveFilters = useMemo(
		() => ({
			...filters,
			cycleId: selectedCycleId,
		}),
		[filters, selectedCycleId],
	);
	const transactions = useTransactions(groupId, effectiveFilters);
	const error =
		group.error ??
		members.error ??
		categories.error ??
		balances.error ??
		transactions.error ??
		me.error;
	useSessionGuard(error);

	const applyFilters = useCallback(
		(next: TransactionFilters) => {
			const qs = buildFilterQueryString({
				...next,
				...(rawCycleParam === "all"
					? {}
					: next.cycleId
						? {}
						: selectedCycleId && selectedCycleId !== "current"
							? { cycleId: selectedCycleId }
							: {}),
			});
			const finalQs =
				rawCycleParam === "all" && !next.cycleId
					? qs
						? `${qs}&cycleId=all`
						: "cycleId=all"
					: qs;
			router.replace(
				`/g/${encodeURIComponent(groupId)}${finalQs ? `?${finalQs}` : ""}`,
			);
		},
		[groupId, router, rawCycleParam, selectedCycleId],
	);
	const handleCycleSelect = useCallback(
		(nextCycleId: "current" | string | undefined) => {
			const baseQs = buildFilterQueryString({ ...filters, cycleId: undefined });
			const cyclePart =
				nextCycleId === undefined
					? "cycleId=all"
					: nextCycleId === "current"
						? ""
						: `cycleId=${encodeURIComponent(nextCycleId)}`;
			const combined = [baseQs, cyclePart].filter(Boolean).join("&");
			router.replace(
				`/g/${encodeURIComponent(groupId)}${combined ? `?${combined}` : ""}`,
			);
		},
		[filters, groupId, router],
	);
	const handleSearchChange = useCallback(
		(q: string) => {
			applyFilters({ ...filters, ...(q ? { q } : { q: undefined }) });
		},
		[applyFilters, filters],
	);

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
		categories.isPending ||
		balances.isPending ||
		transactions.isPending ||
		error?.status === 401
	)
		return (
			<main
				aria-busy="true"
				className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-5 px-5 py-6"
			>
				<div className="h-12 rounded-card bg-sunken" />
				<div className="h-28 rounded-card bg-sunken" />
				<div className="h-72 rounded-card bg-sunken" />
			</main>
		);
	if (
		(me.isError && !me.data) ||
		(group.isError && !group.data) ||
		(members.isError && !members.data) ||
		(categories.isError && !categories.data) ||
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
						void categories.refetch();
						void balances.refetch();
						void transactions.refetch();
					}}
					isRetrying={
						group.isFetching ||
						members.isFetching ||
						categories.isFetching ||
						balances.isFetching ||
						transactions.isFetching
					}
				/>
			</main>
		);
	const hasTransactions =
		(transactions.data.pages[0]?.transactions.length ?? 0) > 0;
	const closedCycles = cycles.data?.cycles ?? [];
	const selectedClosedCycle =
		selectedCycleId && selectedCycleId !== "current"
			? closedCycles.find((cycle) => cycle.id === selectedCycleId)
			: undefined;
	const balance =
		balances.data.balances.find(
			(balance) => balance.memberId === group.data.myMemberId,
		)?.balance ?? 0;
	const dueRecurring =
		group.data.role !== "viewer" && !group.data.archivedAt
			? (recurringQuery.data ?? []).filter(
					(item) => item.pendingDueDate !== null,
				)
			: [];
	return (
		<main className="mx-auto flex h-dvh max-w-[430px] flex-col gap-4 px-5 pb-[100px] pt-6">
			<GroupNavHeader groupId={groupId} />
			{!filtersActive && <BalanceBlock groupId={groupId} balance={balance} />}
			{dueRecurring.length > 0 && (
				<div className="grid gap-2">
					{dueRecurring.map((item) => (
						<Link
							key={item.id}
							href={`/g/${encodeURIComponent(groupId)}/tx/new?form=1&recurringId=${encodeURIComponent(item.id)}`}
							className="flex items-center justify-between gap-2 rounded-[20px] bg-warning-soft px-4 py-3 text-xs font-extrabold text-ink"
						>
							<span className="truncate">
								{t(vi.recurring.pendingDueTemplate, {
									date: formatCalendarDateVN(item.pendingDueDate ?? ""),
								})}{" "}
								· {item.description}
							</span>
							<span className="shrink-0 underline">
								{vi.recurring.enterAmountShort}
							</span>
						</Link>
					))}
				</div>
			)}
			{group.data.myMemberId === null && (
				<Link
					href={`/g/${groupId}/members`}
					className="flex min-h-11 items-center justify-center rounded-pill bg-surface px-4 text-sm font-bold"
				>
					{vi.feed.chooseShape}
				</Link>
			)}
			{group.data.role !== "viewer" && (
				<Link
					href={`/g/${groupId}/members`}
					className="flex min-h-11 items-center justify-center text-[13px] font-bold"
				>
					{vi.feed.inviteLink}
				</Link>
			)}
			{(hasTransactions || filtersActive || hasClosedCycles) &&
				(atTop || filtersActive) && (
					<StreamSearchBar
						value={filters.q ?? ""}
						onSearchChange={handleSearchChange}
						onOpenFilters={() => setSheetOpen(true)}
						hasFilters={filtersActive}
					/>
				)}
			{cycles.data && closedCycles.length > 0 && (
				<CycleFilterChip
					cycles={closedCycles}
					currentPeriod={cycles.data.currentPeriod}
					selectedCycleId={selectedCycleId}
					onSelect={handleCycleSelect}
				/>
			)}
			{selectedClosedCycle && (
				<div className="flex items-center justify-between gap-2 rounded-[18px] bg-surface px-3.5 py-2 text-xs font-bold text-ink">
					<span className="truncate">
						{t(vi.cycles.viewingBanner, { title: selectedClosedCycle.title })}
					</span>
					<button
						type="button"
						onClick={() => handleCycleSelect("current")}
						className="min-h-11 shrink-0 text-xs font-extrabold underline"
					>
						{vi.cycles.backToCurrent}
					</button>
				</div>
			)}
			<BudgetBanner groupId={groupId} budget={budget.data} />
			{filtersActive && (
				<FilterChips
					filters={filters}
					members={members.data}
					categories={categories.data}
					onChange={applyFilters}
					onClear={() => applyFilters({})}
				/>
			)}
			{hasTransactions ? (
				<ExpenseStream
					groupId={groupId}
					query={transactions}
					members={members.data}
					categories={categories.data}
					myMemberId={group.data.myMemberId}
					onAtTopChange={setAtTop}
				/>
			) : filtersActive ? (
				<div className="my-auto py-12 text-center">
					<p className="text-sm font-semibold text-muted">
						{vi.filter.noResult}
					</p>
				</div>
			) : hasClosedCycles && selectedCycleId === "current" ? (
				<div className="my-auto grid justify-items-center gap-3 py-12 text-center">
					<p className="text-sm font-semibold text-muted">
						{vi.cycles.emptyPeriodError}
					</p>
					<button
						type="button"
						onClick={() => handleCycleSelect(undefined)}
						className="min-h-11 rounded-pill bg-surface px-4 text-xs font-bold text-ink"
					>
						{vi.cycles.allPeriods}
					</button>
				</div>
			) : (
				<EmptyStream
					members={members.data.filter((member) => member.kind === "person")}
					groupId={groupId}
					canInvite={group.data.role !== "viewer"}
				/>
			)}
			{(hasTransactions || filtersActive) && (
				<div className="flex items-center justify-center gap-2">
					<Link
						href={`/g/${groupId}/balances`}
						className="flex min-h-11 items-center justify-center rounded-[22px] bg-surface px-5 text-[13px] font-bold"
					>
						{vi.feed.whoOwesWho}
					</Link>
					<Link
						href={`/g/${groupId}/stats`}
						className="flex min-h-11 items-center justify-center rounded-[22px] bg-surface px-5 text-[13px] font-bold"
					>
						{vi.feed.tripTotal}
					</Link>
				</div>
			)}
			<FilterSheet
				open={sheetOpen}
				filters={filters}
				members={members.data}
				categories={categories.data}
				onApply={applyFilters}
				onClear={() => applyFilters({})}
				onClose={() => setSheetOpen(false)}
			/>
			{group.data.archivedAt ? (
				<div className="fixed bottom-0 left-1/2 w-full max-w-[430px] -translate-x-1/2 border-t border-sunken bg-surface px-5 py-4 text-center text-xs font-bold text-muted">
					{vi.groups.archivedBanner}
				</div>
			) : me.data.emailVerified ? (
				<EntryBar groupId={groupId} readOnly={group.data.role === "viewer"} />
			) : (
				<div className="fixed bottom-0 left-1/2 w-full max-w-[430px] -translate-x-1/2 bg-bg p-5">
					<VerifyEmailBanner />
				</div>
			)}
		</main>
	);
}

export default function GroupPage() {
	return (
		<Suspense fallback={<main aria-busy="true" className="h-dvh bg-sunken" />}>
			<GroupScreen />
		</Suspense>
	);
}
