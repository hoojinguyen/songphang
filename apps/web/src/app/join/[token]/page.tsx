"use client";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useEffect } from "react";
import { JoinForm } from "../../../components/join/JoinForm";
import { LoadError } from "../../../components/ui/LoadError";
import { useInvitePreview } from "../../../lib/invites";
import { useMe } from "../../../lib/session";
import { useSessionGuard } from "../../../lib/use-session-guard";
import { t, vi } from "../../../messages/vi";
export default function JoinPage() {
	const { token } = useParams<{ token: string }>();
	const me = useMe();
	const preview = useInvitePreview(token);
	const router = useRouter();
	useSessionGuard(me.error ?? preview.error);
	useEffect(() => {
		if (preview.data?.alreadyJoined)
			router.replace(`/g/${preview.data.group.id}`);
	}, [preview.data, router]);
	if (preview.error?.code === "INVITE_INVALID")
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center gap-5 px-5 text-center">
				<h1 className="text-[28px] font-black">{vi.join.invalidTitle}</h1>
				<p>{vi.join.invalidHint}</p>
				<Link
					href="/"
					className="flex min-h-11 items-center justify-center rounded-pill bg-ink p-4 font-bold text-surface"
				>
					{vi.common.backToGroups}
				</Link>
			</main>
		);
	if (
		me.isPending ||
		preview.isPending ||
		me.error?.status === 401 ||
		preview.error?.status === 401 ||
		preview.data?.alreadyJoined
	)
		return (
			<main
				aria-busy="true"
				className="mx-auto min-h-dvh max-w-[430px] px-5 py-7"
			>
				<div className="h-96 rounded-card bg-sunken" />
			</main>
		);
	if ((me.isError && !me.data) || preview.isError)
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center px-5">
				<LoadError
					onRetry={() => {
						void me.refetch();
						void preview.refetch();
					}}
					isRetrying={me.isFetching || preview.isFetching}
				/>
			</main>
		);
	return (
		<main className="mx-auto grid min-h-dvh max-w-[430px] content-start gap-5 px-5 pb-7 pt-7">
			<header>
				<p className="text-sm font-semibold text-muted">
					{t(vi.join.invitedBy, { name: preview.data.ownerName })}
				</p>
				<h1 className="mt-2 text-[36px] font-black">
					{preview.data.group.name}
				</h1>
				<p className="mt-2 text-sm text-muted">
					{t(vi.join.summary, {
						members: String(preview.data.memberCount),
						count: String(preview.data.transactionCount),
					})}
				</p>
			</header>
			<h2 className="text-[17px] font-extrabold">{vi.join.question}</h2>
			<JoinForm
				token={token}
				preview={preview.data}
				accountName={me.data.name}
				verified={me.data.emailVerified}
				onRefresh={() => {
					void preview.refetch();
				}}
			/>
		</main>
	);
}
