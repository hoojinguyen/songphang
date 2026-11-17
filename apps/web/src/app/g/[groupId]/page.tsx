"use client";
import Link from "next/link";
import { useParams, useRouter, useSearchParams } from "next/navigation";
import { Suspense, useCallback, useMemo, useState } from "react";
import { BalanceBlock } from "../../../components/feed/BalanceBlock";
import { EmptyStream } from "../../../components/feed/EmptyStream";
import { EntryBar } from "../../../components/feed/EntryBar";
import { ExpenseStream } from "../../../components/feed/ExpenseStream";
import { FilterChips } from "../../../components/feed/FilterChips";
import { FilterSheet } from "../../../components/feed/FilterSheet";
import { StreamSearchBar } from "../../../components/feed/StreamSearchBar";
import { LoadError } from "../../../components/ui/LoadError";
import { MemberShape } from "../../../components/ui/MemberShape";
import { ScreenHeader } from "../../../components/ui/ScreenHeader";
import { VerifyEmailBanner } from "../../../components/ui/VerifyEmailBanner";
import { useBalances } from "../../../lib/balances";
import { useCategories } from "../../../lib/categories";
import { useGroup } from "../../../lib/groups";
import { useMembers } from "../../../lib/members";
import { useMe } from "../../../lib/session";
import {
	buildFilterQueryString,
	hasActiveFilters,
	readTransactionFilters,
	type TransactionFilters,
	useTransactions,
} from "../../../lib/transactions";
import { useSessionGuard } from "../../../lib/use-session-guard";
import { vi } from "../../../messages/vi";

function GroupScreen() {
	const { groupId } = useParams<{ groupId: string }>();
	const searchParams = useSearchParams();
	const paramsKey = searchParams.toString();
	const router = useRouter();
	const filters = useMemo(
		() => readTransactionFilters(new URLSearchParams(paramsKey)),
		[paramsKey],
	);
	const filtersActive = hasActiveFilters(filters);
	const [atTop, setAtTop] = useState(true);
	const [sheetOpen, setSheetOpen] = useState(false);
	const me = useMe();
	const group = useGroup(groupId);
	const members = useMembers(groupId);
	const categories = useCategories(groupId);
	const balances = useBalances(groupId);
	const transactions = useTransactions(groupId, filters);
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
			const qs = buildFilterQueryString(next);
			router.replace(`/g/${encodeURIComponent(groupId)}${qs ? `?${qs}` : ""}`);
		},
		[groupId, router],
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
	const balance =
		balances.data.balances.find(
			(balance) => balance.memberId === group.data.myMemberId,
		)?.balance ?? 0;
	return (
		<main className="mx-auto flex h-dvh max-w-[430px] flex-col gap-4 px-5 pb-[100px] pt-6">
			<ScreenHeader
				title={group.data.name}
				backHref="/"
				backLabel={vi.common.back}
				trailing={
					<Link
						href={`/g/${groupId}/members`}
						aria-label={vi.feed.membersLink}
						className="flex h-12 items-center rounded-[24px] bg-surface px-3"
					>
						{members.data.slice(0, 4).map((member) => (
							<MemberShape key={member.id} {...member} size={24} />
						))}
					</Link>
				}
			/>
			{!filtersActive && <BalanceBlock groupId={groupId} balance={balance} />}
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
			{(hasTransactions || filtersActive) && (atTop || filtersActive) && (
				<StreamSearchBar
					value={filters.q ?? ""}
					onSearchChange={handleSearchChange}
					onOpenFilters={() => setSheetOpen(true)}
					hasFilters={filtersActive}
				/>
			)}
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
					canEdit={group.data.role !== "viewer" && me.data.emailVerified}
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
			) : (
				<EmptyStream
					members={members.data}
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
			{me.data.emailVerified ? (
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
