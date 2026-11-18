"use client";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { Suspense } from "react";
import { Button } from "../../../components/ui/Button";
import { LoadError } from "../../../components/ui/LoadError";
import { VerifyEmailBanner } from "../../../components/ui/VerifyEmailBanner";
import { useClaimChatIdentity } from "../../../lib/chat-links";
import { useMe } from "../../../lib/session";
import { useSessionGuard } from "../../../lib/use-session-guard";
import { t, vi } from "../../../messages/vi";

function LinkTelegramScreen() {
	const code = useSearchParams().get("code")?.trim() ?? "";
	const me = useMe();
	const claim = useClaimChatIdentity();
	useSessionGuard(me.error ?? claim.error);

	if (me.isPending || me.error?.status === 401) {
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center px-5 py-6">
				<div aria-busy="true" className="h-36 rounded-card bg-sunken" />
			</main>
		);
	}
	if (me.isError && !me.data) {
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center px-5 py-6">
				<LoadError
					isRetrying={me.isFetching}
					onRetry={() => {
						void me.refetch();
					}}
				/>
			</main>
		);
	}

	const invalidCode =
		!code || claim.error?.status === 400 || claim.error?.status === 409;

	return (
		<main className="mx-auto grid min-h-dvh max-w-[430px] content-center gap-5 px-5 py-6">
			{!me.data.emailVerified ? (
				<VerifyEmailBanner />
			) : claim.isSuccess ? (
				<>
					<h1 className="text-[24px] font-black">{vi.telegram.linkDone}</h1>
					<Link
						href="/"
						className="flex h-control-md items-center justify-center rounded-pill bg-surface px-6 font-bold"
					>
						{vi.common.backToGroups}
					</Link>
				</>
			) : invalidCode ? (
				<>
					<h1 className="text-[24px] font-black">{vi.telegram.linkInvalid}</h1>
					<Link
						href="/"
						className="flex h-control-md items-center justify-center rounded-pill bg-surface px-6 font-bold"
					>
						{vi.common.backToGroups}
					</Link>
				</>
			) : (
				<>
					<h1 className="break-words text-[24px] font-black">
						{t(vi.telegram.linkConfirm, { email: me.data.email })}
					</h1>
					<Button
						variant="primary"
						size="lg"
						disabled={claim.isPending}
						onClick={() => claim.mutate(code)}
					>
						{vi.telegram.linkButton}
					</Button>
					{claim.isError && (
						<p role="alert" className="text-sm text-coral">
							{vi.common.saveError}
						</p>
					)}
				</>
			)}
		</main>
	);
}

export default function LinkTelegramPage() {
	return (
		<Suspense>
			<LinkTelegramScreen />
		</Suspense>
	);
}
