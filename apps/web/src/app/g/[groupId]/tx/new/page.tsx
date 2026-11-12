"use client";
import Link from "next/link";
import { useParams } from "next/navigation";
import { ExpenseForm } from "../../../../../components/expense-form/ExpenseForm";
import { LoadError } from "../../../../../components/ui/LoadError";
import { ScreenHeader } from "../../../../../components/ui/ScreenHeader";
import { useGroup } from "../../../../../lib/groups";
import { useMembers } from "../../../../../lib/members";
import { useSessionGuard } from "../../../../../lib/use-session-guard";
import { vi } from "../../../../../messages/vi";
export default function NewExpensePage() {
	const { groupId } = useParams<{ groupId: string }>();
	const group = useGroup(groupId);
	const members = useMembers(groupId);
	const error = group.error ?? members.error;
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
	if (group.isPending || members.isPending || error?.status === 401)
		return (
			<main
				aria-busy="true"
				className="mx-auto grid min-h-dvh max-w-[430px] gap-4 p-5"
			>
				<div className="h-12 rounded-card bg-sunken" />
				<div className="h-64 rounded-card bg-sunken" />
				<div className="h-64 rounded-card bg-sunken" />
			</main>
		);
	if (group.isError || members.isError)
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center px-5">
				<LoadError
					onRetry={() => {
						void group.refetch();
						void members.refetch();
					}}
					isRetrying={group.isFetching || members.isFetching}
				/>
			</main>
		);
	return (
		<main className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-4 px-5 py-5">
			<ScreenHeader
				title={vi.expenseForm.title}
				subtitle={group.data.name}
				backHref={`/g/${groupId}`}
				backLabel={vi.common.cancel}
				backIcon="close"
			/>
			<ExpenseForm
				groupId={groupId}
				members={members.data}
				myMemberId={group.data.myMemberId}
			/>
		</main>
	);
}
