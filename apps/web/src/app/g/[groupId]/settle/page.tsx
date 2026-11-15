"use client";
import { MoneyAmount } from "@songphang/contract";
import Link from "next/link";
import { useParams, useRouter, useSearchParams } from "next/navigation";
import { Suspense, useEffect } from "react";
import { z } from "zod";
import { SettlementForm } from "../../../../components/balances/SettlementForm";
import { LoadError } from "../../../../components/ui/LoadError";
import { useBalances } from "../../../../lib/balances";
import { useGroup } from "../../../../lib/groups";
import { useMembers } from "../../../../lib/members";
import { useMe } from "../../../../lib/session";
import { useSessionGuard } from "../../../../lib/use-session-guard";
import { vi } from "../../../../messages/vi";

const Query = z
	.object({
		from: z.uuid(),
		to: z.uuid(),
		amount: z.coerce.number().pipe(MoneyAmount),
	})
	.refine((query) => query.from !== query.to);
function SettleScreen() {
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
		amount: params.get("amount"),
	});
	const from = query.success
		? members.data?.find((m) => m.id === query.data.from)
		: undefined;
	const to = query.success
		? members.data?.find((m) => m.id === query.data.to)
		: undefined;
	useEffect(() => {
		if (members.data && (!query.success || !from || !to))
			router.replace(`/g/${groupId}/balances`);
	}, [members.data, query.success, from, to, router, groupId]);
	if (error?.status === 404)
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center px-5">
				<p>{vi.common.groupNotFound}</p>
				<Link href="/">{vi.common.backToGroups}</Link>
			</main>
		);
	if (group.data?.role === "viewer")
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center px-5">
				<p role="alert">{vi.common.forbidden}</p>
				<Link href={`/g/${groupId}/balances`}>{vi.common.back}</Link>
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
				className="mx-auto h-dvh max-w-[430px] bg-sunken"
			/>
		);
	if (group.isError || members.isError || balances.isError || me.isError)
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
	if (!query.success || !from || !to) return null;
	return (
		<SettlementForm
			key={`${from.id}-${to.id}-${query.data.amount}`}
			groupId={groupId}
			from={from}
			to={to}
			initialAmount={query.data.amount}
			myMemberId={group.data.myMemberId}
			debt={
				-(
					balances.data.balances.find((b) => b.memberId === from.id)?.balance ??
					0
				)
			}
			verified={me.data.emailVerified}
		/>
	);
}
export default function SettlePage() {
	return (
		<Suspense fallback={<main aria-busy="true" className="h-dvh bg-sunken" />}>
			<SettleScreen />
		</Suspense>
	);
}
