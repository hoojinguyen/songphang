"use client";
import Link from "next/link";
import { useParams } from "next/navigation";
import { ApprovalBlock } from "../../../../../../components/transaction/ApprovalBlock";
import { CommentField } from "../../../../../../components/transaction/CommentField";
import { CommentThread } from "../../../../../../components/transaction/CommentThread";
import { DisputeBlock } from "../../../../../../components/transaction/DisputeBlock";
import { TransactionSummary } from "../../../../../../components/transaction/TransactionSummary";
import { LoadError } from "../../../../../../components/ui/LoadError";
import { ScreenHeader } from "../../../../../../components/ui/ScreenHeader";
import { VerifyEmailBanner } from "../../../../../../components/ui/VerifyEmailBanner";
import { useCategories } from "../../../../../../lib/categories";
import { useComments } from "../../../../../../lib/comments";
import { useGroup } from "../../../../../../lib/groups";
import { useMembers } from "../../../../../../lib/members";
import { useMe } from "../../../../../../lib/session";
import { useTransaction } from "../../../../../../lib/transaction-changes";
import { useSessionGuard } from "../../../../../../lib/use-session-guard";
import { vi } from "../../../../../../messages/vi";

export default function TransactionViewPage() {
	const { groupId, transactionId } = useParams<{
		groupId: string;
		transactionId: string;
	}>();
	const me = useMe();
	const group = useGroup(groupId);
	const members = useMembers(groupId);
	const categories = useCategories(groupId);
	const txQuery = useTransaction(groupId, transactionId);
	const commentsQuery = useComments(groupId, transactionId);
	const error =
		group.error ??
		members.error ??
		categories.error ??
		txQuery.error ??
		me.error;
	useSessionGuard(error);

	if (error?.status === 404) {
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center gap-4 px-5 text-center">
				<p>{vi.common.groupNotFound}</p>
				<Link href="/" className="flex min-h-11 items-center justify-center">
					{vi.common.backToGroups}
				</Link>
			</main>
		);
	}
	if (
		me.isPending ||
		group.isPending ||
		members.isPending ||
		categories.isPending ||
		txQuery.isPending ||
		error?.status === 401
	) {
		return (
			<main
				aria-busy="true"
				className="mx-auto grid min-h-dvh max-w-[430px] gap-4 p-5"
			>
				<div className="h-12 rounded-card bg-sunken" />
				<div className="h-64 rounded-card bg-sunken" />
				<div className="h-32 rounded-card bg-sunken" />
			</main>
		);
	}
	if (
		(me.isError && !me.data) ||
		(group.isError && !group.data) ||
		(members.isError && !members.data) ||
		(categories.isError && !categories.data) ||
		!txQuery.data
	) {
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center px-5">
				<LoadError
					onRetry={() => {
						void me.refetch();
						void group.refetch();
						void members.refetch();
						void categories.refetch();
						void txQuery.refetch();
					}}
					isRetrying={
						me.isFetching ||
						group.isFetching ||
						members.isFetching ||
						categories.isFetching ||
						txQuery.isFetching
					}
				/>
			</main>
		);
	}

	const transaction = txQuery.data;
	const canEdit =
		group.data.role !== "viewer" &&
		me.data.emailVerified &&
		transaction.deletedAt === null;
	const comments =
		commentsQuery.data?.pages.flatMap((page) => page.comments) ?? [];

	return (
		<main className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-4 px-5 pb-28 pt-6">
			<ScreenHeader
				title={transaction.description}
				subtitle={group.data.name}
				backHref={`/g/${groupId}`}
				backLabel={vi.common.back}
				trailing={
					canEdit ? (
						<Link
							href={`/g/${groupId}/tx/${transactionId}`}
							className="flex min-h-11 items-center rounded-[18px] bg-surface px-4 text-sm font-bold"
						>
							{vi.transactionView.editLink}
						</Link>
					) : undefined
				}
			/>
			{!me.data.emailVerified && <VerifyEmailBanner />}
			<TransactionSummary
				groupId={groupId}
				transaction={transaction}
				members={members.data}
				categories={categories.data}
			/>
			<ApprovalBlock
				groupId={groupId}
				transactionId={transactionId}
				approval={transaction.approval}
				ownerName={group.data.ownerName}
				role={group.data.role}
				verified={me.data.emailVerified}
				deleted={transaction.deletedAt !== null}
			/>
			<DisputeBlock
				groupId={groupId}
				transactionId={transactionId}
				dispute={transaction.dispute}
				role={group.data.role}
				verified={me.data.emailVerified}
				deleted={transaction.deletedAt !== null}
			/>
			<CommentThread
				groupId={groupId}
				transactionId={transactionId}
				comments={comments}
				role={group.data.role}
				verified={me.data.emailVerified}
				isPending={commentsQuery.isPending}
				isError={commentsQuery.isError}
				isFetching={commentsQuery.isFetching}
				hasNextPage={Boolean(commentsQuery.hasNextPage)}
				isFetchingNextPage={commentsQuery.isFetchingNextPage}
				onRetry={() => void commentsQuery.refetch()}
				onLoadMore={() => void commentsQuery.fetchNextPage()}
			/>
			<CommentField
				groupId={groupId}
				transactionId={transactionId}
				verified={me.data.emailVerified}
			/>
		</main>
	);
}
