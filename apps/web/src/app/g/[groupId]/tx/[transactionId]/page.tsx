"use client";
import type { TransactionDto } from "@songphang/contract";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useState } from "react";
import { ExpenseForm } from "../../../../../components/expense-form/ExpenseForm";
import { PhotoRow } from "../../../../../components/expense-form/PhotoRow";
import { LoadError } from "../../../../../components/ui/LoadError";
import { ScreenHeader } from "../../../../../components/ui/ScreenHeader";
import { VerifyEmailBanner } from "../../../../../components/ui/VerifyEmailBanner";
import { useGroup } from "../../../../../lib/groups";
import { useMembers } from "../../../../../lib/members";
import { formatMoney } from "../../../../../lib/money";
import { useMe } from "../../../../../lib/session";
import { useTransaction } from "../../../../../lib/transaction-changes";
import { useSessionGuard } from "../../../../../lib/use-session-guard";
import { vi } from "../../../../../messages/vi";
export default function EditPage() {
	const { groupId, transactionId } = useParams<{
		groupId: string;
		transactionId: string;
	}>();
	const me = useMe();
	const group = useGroup(groupId);
	const members = useMembers(groupId);
	const query = useTransaction(groupId, transactionId);
	const error = group.error ?? members.error ?? query.error ?? me.error;
	useSessionGuard(error);
	const loadError = (
		<LoadError
			onRetry={() => {
				void me.refetch();
				void group.refetch();
				void members.refetch();
				void query.refetch();
			}}
			isRetrying={
				me.isFetching ||
				group.isFetching ||
				members.isFetching ||
				query.isFetching
			}
		/>
	);
	return (
		<main className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-4 p-5">
			{error?.status === 404 ? (
				<p>{vi.common.groupNotFound}</p>
			) : error?.status === 401 ? (
				<div aria-busy="true" className="h-96 rounded-card bg-sunken" />
			) : error && (!query.data || !members.data || !group.data || !me.data) ? (
				loadError
			) : query.isPending ||
				!query.data ||
				!members.data ||
				!group.data ||
				!me.data ? (
				<div aria-busy="true" className="h-96 rounded-card bg-sunken" />
			) : group.data.role === "viewer" ? (
				query.data.attachments.length > 0 && !query.data.deletedAt ? (
					<div className="grid gap-4">
						<ScreenHeader
							title={query.data.description}
							subtitle={formatMoney(query.data.amount)}
							backHref={`/g/${groupId}/tx/${transactionId}/view`}
							backLabel={vi.common.back}
						/>
						<PhotoRow
							groupId={groupId}
							attachments={query.data.attachments}
							readOnly
						/>
					</div>
				) : (
					<p role="alert">{vi.common.forbidden}</p>
				)
			) : !me.data.emailVerified ? (
				<VerifyEmailBanner />
			) : (
				<>
					<LoadedEdit
						key={transactionId}
						groupId={groupId}
						transaction={query.data}
						members={members.data}
						myMemberId={group.data.myMemberId}
					/>
					{error && loadError}
				</>
			)}
			<Link
				className="min-h-11 text-center"
				href={`/g/${groupId}/tx/${transactionId}/view`}
			>
				{vi.common.back}
			</Link>
		</main>
	);
}
function LoadedEdit({
	groupId,
	transaction,
	members,
	myMemberId,
}: {
	groupId: string;
	transaction: TransactionDto;
	members: Parameters<typeof ExpenseForm>[0]["members"];
	myMemberId: string | null;
}) {
	const [loaded, setLoaded] = useState(transaction);
	if (transaction.deletedAt)
		return <p role="status">{vi.expenseForm.deletedNotice}</p>;
	return (
		<ExpenseForm
			key={loaded.version}
			groupId={groupId}
			transaction={loaded}
			members={members}
			myMemberId={myMemberId}
			{...(transaction.version > loaded.version
				? { current: transaction }
				: {})}
			onReload={setLoaded}
		/>
	);
}
