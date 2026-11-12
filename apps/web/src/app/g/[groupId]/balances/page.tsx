"use client";
import Link from "next/link";
import { useParams } from "next/navigation";
import { AllSettled } from "../../../../components/balances/AllSettled";
import { BalanceBars } from "../../../../components/balances/BalanceBars";
import { SettlementCard } from "../../../../components/balances/SettlementCard";
import { LoadError } from "../../../../components/ui/LoadError";
import { ScreenHeader } from "../../../../components/ui/ScreenHeader";
import { useBalances } from "../../../../lib/balances";
import { useGroup } from "../../../../lib/groups";
import { useMembers } from "../../../../lib/members";
import { useTransactions } from "../../../../lib/transactions";
import { useSessionGuard } from "../../../../lib/use-session-guard";
import { t, vi } from "../../../../messages/vi";
export default function BalancesPage() {
	const { groupId } = useParams<{ groupId: string }>();
	const group = useGroup(groupId);
	const members = useMembers(groupId);
	const balances = useBalances(groupId);
	const transactions = useTransactions(groupId);
	const error =
		group.error ?? members.error ?? balances.error ?? transactions.error;
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
		group.isError ||
		members.isError ||
		balances.isError ||
		transactions.isError
	)
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center px-5">
				<LoadError
					onRetry={() => {
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
	return (
		<main className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-5 px-5 py-6">
			<ScreenHeader
				title={group.data.name}
				backHref={`/g/${groupId}`}
				backLabel={vi.common.back}
			/>
			{!hasTransactions ? (
				<div className="my-auto py-12">
					<h2 className="text-[34px] font-black">{vi.balances.emptyTitle}</h2>
					<p className="mt-3 text-sm text-muted">{vi.balances.emptyHint}</p>
				</div>
			) : transfers.length === 0 ? (
				<AllSettled
					groupId={groupId}
					members={members.data}
					myMemberId={group.data.myMemberId}
				/>
			) : (
				<>
					<div>
						<h2 className="text-[34px] font-black">
							{t(vi.balances.headline, { count: String(transfers.length) })}
						</h2>
						<p className="mt-2 text-sm text-muted">
							{balances.data.minimized
								? vi.balances.minimizedHint
								: vi.balances.pairwiseHint}
						</p>
					</div>
					{transfers.map((transfer) => (
						<SettlementCard
							key={`${transfer.fromMemberId}-${transfer.toMemberId}`}
							transfer={transfer}
							members={members.data}
							myMemberId={group.data.myMemberId}
						/>
					))}
					<BalanceBars
						balances={balances.data.balances}
						members={members.data}
					/>
				</>
			)}
		</main>
	);
}
