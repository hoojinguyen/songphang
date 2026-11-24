"use client";
import { useQueryClient } from "@tanstack/react-query";
import Link from "next/link";
import { useEffect, useState } from "react";
import { Bell } from "../components/notifications/Bell";
import { OverviewSummaryCard } from "../components/overview/OverviewSummaryCard";
import { PendingActionsList } from "../components/overview/PendingActionsList";
import { PersonalLedgerList } from "../components/overview/PersonalLedgerList";
import { Button } from "../components/ui/Button";
import { LoadError } from "../components/ui/LoadError";
import { MemberShape } from "../components/ui/MemberShape";
import { VerifyEmailBanner } from "../components/ui/VerifyEmailBanner";
import { formatSignedAmount } from "../lib/money";
import { useOverview, usePersonalTransactions } from "../lib/overview";
import { useMe } from "../lib/session";
import { useSessionGuard } from "../lib/use-session-guard";
import { t, vi } from "../messages/vi";

function OverviewSkeleton() {
	return (
		<main
			aria-busy="true"
			className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-6 px-5 py-6"
		>
			<div className="h-16 rounded-card bg-sunken" />
			<div className="h-44 rounded-card bg-sunken" />
			<div className="h-32 rounded-card bg-sunken" />
			<div className="h-48 rounded-card bg-sunken" />
		</main>
	);
}

function OverviewHeader({ name }: { name: string }) {
	return (
		<header className="flex items-center justify-between gap-4">
			<div>
				<p className="text-sm text-muted">{t(vi.groups.greeting, { name })}</p>
				<h1 className="text-title font-black">{vi.overview.title}</h1>
			</div>
			<div className="flex items-center gap-2">
				<Bell />
				<Link
					href="/account"
					aria-label={vi.account.title}
					className="shrink-0 rounded-pill focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ink"
				>
					<MemberShape shape="circle" color="mint" size={52} name={name} />
				</Link>
			</div>
		</header>
	);
}

function OverviewContent({ name }: { name: string }) {
	const me = useMe();
	const overview = useOverview();
	const recentTransactionsQuery = usePersonalTransactions();
	const client = useQueryClient();
	const [deleted] = useState(
		() => client.getQueryData(["notice", "deleted"]) === true,
	);
	const [removed] = useState(
		() => client.getQueryData(["notice", "removed"]) === true,
	);

	useEffect(() => {
		client.removeQueries({ queryKey: ["notice", "removed"] });
		client.removeQueries({ queryKey: ["notice", "deleted"] });
	}, [client]);

	useSessionGuard(overview.error ?? recentTransactionsQuery.error);

	if (overview.isPending) {
		return <OverviewSkeleton />;
	}

	if (overview.isError) {
		return (
			<main className="mx-auto flex min-h-dvh max-w-[430px] flex-col items-center justify-center gap-4 px-5 text-center">
				<LoadError
					onRetry={() => {
						void overview.refetch();
					}}
					isRetrying={overview.isFetching}
				/>
			</main>
		);
	}

	const recentTransactions =
		recentTransactionsQuery.data?.pages[0]?.items.slice(0, 5) ?? [];

	return (
		<main className="mx-auto flex min-h-dvh w-full max-w-[430px] flex-col gap-6 px-5 pb-24 pt-6">
			<OverviewHeader name={name} />
			{removed && (
				<p role="status" className="text-sm font-bold text-ink">
					{vi.common.removed}
				</p>
			)}
			{deleted && (
				<p role="status" className="text-sm font-bold text-ink">
					{vi.groups.deleted}
				</p>
			)}

			{me.data?.emailVerified === false && <VerifyEmailBanner />}

			<OverviewSummaryCard overview={overview.data} />

			{overview.data.pendingActions.length > 0 && (
				<PendingActionsList actions={overview.data.pendingActions} />
			)}

			<section className="grid gap-3">
				<div className="flex items-center justify-between">
					<h2 className="text-base font-extrabold text-ink">
						{vi.overview.groupBalances}
					</h2>
					<Link
						href="/groups"
						className="text-xs font-bold text-muted hover:text-ink"
					>
						{vi.tabs.groups}
					</Link>
				</div>
				{overview.data.groupBalances.length === 0 ? (
					<div className="rounded-[24px] bg-surface p-6 text-center text-sm font-medium text-muted">
						{vi.groups.emptyHint}
					</div>
				) : (
					<div className="grid gap-2">
						{overview.data.groupBalances.map((group) => {
							const tone =
								group.myBalance > 0
									? "text-credit"
									: group.myBalance < 0
										? "text-debt"
										: "text-muted";
							const isArchived = Boolean(group.archivedAt);

							return (
								<Link
									key={group.groupId}
									href={`/g/${group.groupId}`}
									className="flex items-center justify-between gap-3 rounded-[24px] bg-surface p-4 transition-colors hover:bg-surface-raised"
								>
									<div className="min-w-0 flex-1">
										<div className="flex items-center gap-1.5">
											<div className="flex gap-1">
												{group.previewMembers.map((m) => (
													<MemberShape key={m.id} {...m} size={20} />
												))}
											</div>
											<span className="truncate text-sm font-bold text-ink">
												{group.groupName}
											</span>
											{isArchived && (
												<span className="rounded-md bg-sunken px-1.5 py-0.5 text-[10px] font-bold text-muted">
													{vi.groups.tabArchived}
												</span>
											)}
										</div>
										<p className="mt-1 text-xs text-muted">
											{t(vi.groups.memberCount, {
												count: String(group.memberCount),
											})}
										</p>
									</div>
									<div className="shrink-0 text-right">
										<p className={`tabular-nums text-sm font-black ${tone}`}>
											{formatSignedAmount(group.myBalance)} {vi.common.currency}
										</p>
									</div>
								</Link>
							);
						})}
					</div>
				)}
			</section>

			<section className="grid gap-3">
				<div className="flex items-center justify-between">
					<h2 className="text-base font-extrabold text-ink">
						{vi.overview.recentTransactions}
					</h2>
					<Link
						href="/ledger"
						className="text-xs font-bold text-muted hover:text-ink"
					>
						{vi.overview.viewAllTransactions}
					</Link>
				</div>
				{recentTransactionsQuery.isPending ? (
					<div aria-busy="true" className="grid gap-2">
						<div className="h-20 rounded-[24px] bg-sunken" />
						<div className="h-20 rounded-[24px] bg-sunken" />
					</div>
				) : recentTransactionsQuery.isError ? (
					<LoadError
						onRetry={() => {
							void recentTransactionsQuery.refetch();
						}}
						isRetrying={recentTransactionsQuery.isFetching}
					/>
				) : (
					<PersonalLedgerList items={recentTransactions} />
				)}
			</section>
		</main>
	);
}

export default function OverviewPage() {
	const me = useMe();
	useSessionGuard(me.error);
	if (me.isPending || me.error?.status === 401) return <OverviewSkeleton />;
	if (me.isError)
		return (
			<main className="mx-auto flex min-h-dvh max-w-[430px] flex-col items-center justify-center gap-4 px-5 text-center">
				<p role="alert">{vi.common.loadError}</p>
				<Button
					variant="primary"
					onClick={() => {
						void me.refetch();
					}}
					disabled={me.isFetching}
				>
					{vi.common.retry}
				</Button>
			</main>
		);
	return <OverviewContent name={me.data.name} />;
}
