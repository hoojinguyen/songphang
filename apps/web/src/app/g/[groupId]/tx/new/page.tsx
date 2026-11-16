"use client";
import Link from "next/link";
import { useParams, useSearchParams } from "next/navigation";
import { ExpenseForm } from "../../../../../components/expense-form/ExpenseForm";
import { LoadError } from "../../../../../components/ui/LoadError";
import { VerifyEmailBanner } from "../../../../../components/ui/VerifyEmailBanner";
import { useGroup } from "../../../../../lib/groups";
import { useMembers } from "../../../../../lib/members";
import { useMe } from "../../../../../lib/session";
import { useSessionGuard } from "../../../../../lib/use-session-guard";
import { vi } from "../../../../../messages/vi";
import { ComposeScreen } from "./ComposeScreen";
export default function NewExpensePage() {
	const { groupId } = useParams<{ groupId: string }>();
	const search = useSearchParams();

	const me = useMe();
	const group = useGroup(groupId);
	const members = useMembers(groupId);
	const error = group.error ?? members.error ?? me.error;
	useSessionGuard(error);
	if (group.data?.role === "viewer")
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center px-5">
				<p role="alert">{vi.common.forbidden}</p>
				<Link href={`/g/${groupId}`}>{vi.common.back}</Link>
			</main>
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
		error?.status === 401
	)
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
	if (
		(me.isError && !me.data) ||
		(group.isError && !group.data) ||
		(members.isError && !members.data)
	)
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center px-5">
				<LoadError
					onRetry={() => {
						void me.refetch();
						void group.refetch();
						void members.refetch();
					}}
					isRetrying={group.isFetching || members.isFetching}
				/>
			</main>
		);
	return (
		<main className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-4 px-5 py-5">
			{!me.data.emailVerified ? (
				<VerifyEmailBanner />
			) : !search.has("form") ? (
				<ComposeScreen
					groupId={groupId}
					groupName={group.data.name}
					members={members.data}
				/>
			) : (
				<ExpenseForm
					groupId={groupId}
					members={members.data}
					myMemberId={group.data.myMemberId}
				/>
			)}
		</main>
	);
}
