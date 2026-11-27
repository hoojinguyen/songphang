"use client";
import Link from "next/link";
import { useParams, useSearchParams } from "next/navigation";
import { ExpenseForm } from "../../../../../components/expense-form/ExpenseForm";
import { ReceiptReview } from "../../../../../components/receipt/ReceiptReview";
import { LoadError } from "../../../../../components/ui/LoadError";
import { VerifyEmailBanner } from "../../../../../components/ui/VerifyEmailBanner";
import { useGroup } from "../../../../../lib/groups";
import { useMembers } from "../../../../../lib/members";
import { useRecurringExpenses } from "../../../../../lib/recurring-expenses";
import { useMe } from "../../../../../lib/session";
import { useSessionGuard } from "../../../../../lib/use-session-guard";
import { vi } from "../../../../../messages/vi";
import { ComposeScreen } from "./ComposeScreen";
export default function NewExpensePage() {
	const { groupId } = useParams<{ groupId: string }>();
	const search = useSearchParams();

	const recurringId = search.get("recurringId");
	const me = useMe();
	const group = useGroup(groupId);
	const members = useMembers(groupId);
	const recurringQuery = useRecurringExpenses(groupId, Boolean(recurringId));
	const error =
		group.error ?? members.error ?? me.error ?? recurringQuery.error;
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
		(Boolean(recurringId) && recurringQuery.isPending) ||
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
		(members.isError && !members.data) ||
		(Boolean(recurringId) && recurringQuery.isError && !recurringQuery.data)
	)
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center px-5">
				<LoadError
					onRetry={() => {
						void me.refetch();
						void group.refetch();
						void members.refetch();
						if (recurringId) void recurringQuery.refetch();
					}}
					isRetrying={
						group.isFetching ||
						members.isFetching ||
						(Boolean(recurringId) && recurringQuery.isFetching)
					}
				/>
			</main>
		);
	const scanId = search.get("scan");
	const recurringTemplate = recurringId
		? recurringQuery.data?.find((item) => item.id === recurringId)
		: undefined;
	if (recurringId && !recurringTemplate)
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center gap-4 px-5 text-center">
				<p role="alert">{vi.common.loadError}</p>
				<Link
					href={`/g/${groupId}`}
					className="flex min-h-11 items-center justify-center"
				>
					{vi.common.back}
				</Link>
			</main>
		);
	return (
		<main className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-4 px-5 py-5">
			{!me.data.emailVerified ? (
				<VerifyEmailBanner />
			) : scanId ? (
				<ReceiptReview
					groupId={groupId}
					scanId={scanId}
					members={members.data}
					myMemberId={group.data.myMemberId}
				/>
			) : !search.has("form") ? (
				<ComposeScreen
					writerMemberId={group.data.myMemberId}
					groupId={groupId}
					groupName={group.data.name}
					members={members.data}
				/>
			) : (
				<ExpenseForm
					key={recurringTemplate?.id ?? "default"}
					groupId={groupId}
					members={members.data}
					myMemberId={group.data.myMemberId}
					prefill={{
						...(search.get("type") === "transfer" ? { type: "transfer" } : {}),
						...(search.get("from") ? { from: search.get("from") } : {}),
						...(search.get("to") ? { to: search.get("to") } : {}),
						...(search.get("attachmentId")
							? { attachmentId: search.get("attachmentId") }
							: {}),
						...(search.get("text") ? { text: search.get("text") } : {}),
						...(recurringTemplate ? { recurringTemplate } : {}),
					}}
				/>
			)}
		</main>
	);
}
