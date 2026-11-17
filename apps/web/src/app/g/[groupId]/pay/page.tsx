"use client";
import Link from "next/link";
import { useParams, useRouter, useSearchParams } from "next/navigation";
import { Suspense, useEffect } from "react";
import { z } from "zod";
import { PayContent } from "../../../../components/pay/PayContent";
import { LoadError } from "../../../../components/ui/LoadError";
import { useBalances } from "../../../../lib/balances";
import { useGroup } from "../../../../lib/groups";
import { useMembers } from "../../../../lib/members";
import { useMe } from "../../../../lib/session";
import { useSessionGuard } from "../../../../lib/use-session-guard";
import { vi } from "../../../../messages/vi";

const Query = z
	.object({ from: z.uuid(), to: z.uuid() })
	.refine((query) => query.from !== query.to);

function PayScreen() {
	const { groupId } = useParams<{ groupId: string }>();
	const params = useSearchParams();
	const router = useRouter();
	const group = useGroup(groupId);
	const members = useMembers(groupId);
	const balances = useBalances(groupId);
	const me = useMe();
	const error = group.error ?? members.error ?? balances.error ?? me.error;
	useSessionGuard(error);
	const query = Query.safeParse({
		from: params.get("from"),
		to: params.get("to"),
	});
	const from = query.success
		? members.data?.find((member) => member.id === query.data.from)
		: undefined;
	const to = query.success
		? members.data?.find((member) => member.id === query.data.to)
		: undefined;
	const transfer =
		from && to
			? balances.data?.transfers.find(
					(candidate) =>
						candidate.fromMemberId === from.id &&
						candidate.toMemberId === to.id,
				)
			: undefined;

	useEffect(() => {
		if (
			balances.data &&
			members.data &&
			(!query.success || !from || !to || !transfer)
		)
			router.replace(`/g/${groupId}/balances`);
	}, [
		balances.data,
		members.data,
		query.success,
		from,
		to,
		transfer,
		router,
		groupId,
	]);

	if (error?.status === 404)
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center gap-4 px-5 text-center">
				<p>{vi.common.groupNotFound}</p>
				<Link href="/">{vi.common.backToGroups}</Link>
			</main>
		);
	if (
		group.isPending ||
		members.isPending ||
		balances.isPending ||
		me.isPending ||
		error?.status === 401
	)
		return (
			<main
				aria-busy="true"
				className="mx-auto grid min-h-dvh max-w-[430px] gap-5 p-5"
			>
				<div className="h-12 rounded-card bg-sunken" />
				<div className="h-64 rounded-card bg-sunken" />
			</main>
		);
	if (
		(group.isError && !group.data) ||
		(members.isError && !members.data) ||
		(balances.isError && !balances.data) ||
		(me.isError && !me.data)
	)
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center px-5">
				<LoadError
					onRetry={() => {
						void group.refetch();
						void members.refetch();
						void balances.refetch();
						void me.refetch();
					}}
					isRetrying={
						group.isFetching ||
						members.isFetching ||
						balances.isFetching ||
						me.isFetching
					}
				/>
			</main>
		);
	if (!from || !to || !transfer) return null;

	return (
		<PayContent
			groupId={groupId}
			from={from}
			to={to}
			transfer={transfer}
			myMemberId={group.data.myMemberId}
			role={group.data.role}
			verified={me.data.emailVerified}
		/>
	);
}

export default function PayPage() {
	return (
		<Suspense fallback={<main aria-busy="true" className="h-dvh bg-sunken" />}>
			<PayScreen />
		</Suspense>
	);
}
