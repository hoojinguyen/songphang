"use client";
import Link from "next/link";
import { useParams } from "next/navigation";
import { BalanceBlock } from "../../../components/feed/BalanceBlock";
import { EmptyStream } from "../../../components/feed/EmptyStream";
import { EntryBar } from "../../../components/feed/EntryBar";
import { ExpenseStream } from "../../../components/feed/ExpenseStream";
import { LoadError } from "../../../components/ui/LoadError";
import { MemberShape } from "../../../components/ui/MemberShape";
import { ScreenHeader } from "../../../components/ui/ScreenHeader";
import { useBalances } from "../../../lib/balances";
import { useGroup } from "../../../lib/groups";
import { useMembers } from "../../../lib/members";
import { useTransactions } from "../../../lib/transactions";
import { useSessionGuard } from "../../../lib/use-session-guard";
import { vi } from "../../../messages/vi";
export default function GroupPage() {
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
				className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-5 px-5 py-6"
			>
				<div className="h-12 rounded-card bg-sunken" />
				<div className="h-28 rounded-card bg-sunken" />
				<div className="h-72 rounded-card bg-sunken" />
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
			<BalanceBlock groupId={groupId} balance={balance} />
			{hasTransactions ? (
				<>
					<ExpenseStream
						query={transactions}
						members={members.data}
						myMemberId={group.data.myMemberId}
					/>
					<Link
						href={`/g/${groupId}/balances`}
						className="flex min-h-11 items-center justify-center self-center rounded-[22px] bg-surface px-5 text-[13px] font-bold"
					>
						{vi.feed.whoOwesWho}
					</Link>
				</>
			) : (
				<EmptyStream members={members.data} />
			)}
			<EntryBar groupId={groupId} />
		</main>
	);
}
