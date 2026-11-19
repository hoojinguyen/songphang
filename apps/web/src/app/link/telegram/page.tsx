"use client";
import type { StartTelegramPairingResponse } from "@songphang/contract";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { Suspense, useState } from "react";
import { TelegramPairingStepView } from "../../../components/account/TelegramPairingStepView";
import { Button } from "../../../components/ui/Button";
import { LoadError } from "../../../components/ui/LoadError";
import { VerifyEmailBanner } from "../../../components/ui/VerifyEmailBanner";
import {
	useCancelTelegramPairing,
	useConfirmTelegramPairing,
	useStartTelegramPairing,
	useTelegramPairing,
} from "../../../lib/chat-links";
import { useFeatures } from "../../../lib/features";
import { useMe } from "../../../lib/session";
import { useSessionGuard } from "../../../lib/use-session-guard";
import { t, vi } from "../../../messages/vi";

function LinkTelegramScreen() {
	const legacyCode = useSearchParams().get("code")?.trim() ?? "";
	const features = useFeatures();
	const me = useMe();
	const startPairing = useStartTelegramPairing();
	const confirmPairing = useConfirmTelegramPairing();
	const cancelPairing = useCancelTelegramPairing();
	const [started, setStarted] = useState<StartTelegramPairingResponse | null>(
		null,
	);

	const polling = useTelegramPairing(
		started?.pairing.id ?? null,
		Boolean(started) && !confirmPairing.isSuccess && !cancelPairing.isSuccess,
	);

	useSessionGuard(
		me.error ??
			startPairing.error ??
			polling.error ??
			confirmPairing.error ??
			cancelPairing.error ??
			null,
	);

	if (me.isPending || me.error?.status === 401 || features.isPending) {
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

	const pairing = polling.data?.pairing ?? started?.pairing ?? null;
	const telegramDisabled =
		features.data?.telegram === false || startPairing.error?.status === 404;

	function resetFlow() {
		setStarted(null);
		startPairing.reset();
		confirmPairing.reset();
		cancelPairing.reset();
	}

	async function handleStart() {
		confirmPairing.reset();
		cancelPairing.reset();
		const created = await startPairing.mutateAsync().catch(() => null);
		if (created) setStarted(created);
	}

	if (!me.data.emailVerified) {
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center gap-5 px-5 py-6">
				<VerifyEmailBanner />
			</main>
		);
	}

	if (legacyCode.length > 0 || telegramDisabled) {
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center gap-5 px-5 py-6">
				<h1 className="text-[24px] font-black">{vi.telegram.linkInvalid}</h1>
				{!telegramDisabled && (
					<Link
						href="/link/telegram"
						className="flex min-h-12 items-center justify-center rounded-pill bg-ink px-6 font-bold text-surface"
					>
						{vi.telegram.startNewPairingButton}
					</Link>
				)}
				<Link
					href="/"
					className="flex min-h-12 items-center justify-center rounded-pill bg-surface px-6 font-bold text-ink"
				>
					{vi.common.backToGroups}
				</Link>
			</main>
		);
	}

	if (confirmPairing.isSuccess || pairing?.status === "completed") {
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center gap-5 px-5 py-6">
				<h1 className="text-[24px] font-black">{vi.telegram.linkDone}</h1>
				<Link
					href="/"
					className="flex min-h-12 items-center justify-center rounded-pill bg-surface px-6 font-bold text-ink"
				>
					{vi.common.backToGroups}
				</Link>
			</main>
		);
	}

	const isInvalidTerminal =
		cancelPairing.isSuccess ||
		pairing?.status === "cancelled" ||
		pairing?.status === "expired" ||
		polling.error?.status === 404 ||
		confirmPairing.error?.status === 400 ||
		confirmPairing.error?.status === 404 ||
		confirmPairing.error?.status === 409;

	if (isInvalidTerminal) {
		const isTaken = confirmPairing.error?.status === 409;
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center gap-5 px-5 py-6">
				<h1 className="text-[24px] font-black">
					{isTaken ? vi.telegram.identityTaken : vi.telegram.linkInvalid}
				</h1>
				<Button variant="primary" size="lg" onClick={resetFlow}>
					{vi.telegram.startNewPairingButton}
				</Button>
				<Link
					href="/"
					className="flex min-h-12 items-center justify-center rounded-pill bg-surface px-6 font-bold text-ink"
				>
					{vi.common.backToGroups}
				</Link>
			</main>
		);
	}

	if (started && pairing) {
		return (
			<TelegramPairingStepView
				started={started}
				pairing={pairing}
				email={me.data.email}
				isConfirmPending={confirmPairing.isPending}
				isCancelPending={cancelPairing.isPending}
				errorMessage={
					confirmPairing.isError || cancelPairing.isError
						? vi.common.saveError
						: null
				}
				onConfirm={() => confirmPairing.mutate(pairing.id)}
				onCancel={() => cancelPairing.mutate(pairing.id)}
			/>
		);
	}

	return (
		<main className="mx-auto grid min-h-dvh w-full max-w-[430px] content-center gap-5 px-5 py-6">
			<h1 className="min-w-0 [overflow-wrap:anywhere] text-[24px] font-black">
				{t(vi.telegram.linkConfirm, { email: me.data.email })}
			</h1>
			<p className="text-sm text-muted">{vi.telegram.startPairingHint}</p>
			<Button
				variant="primary"
				size="lg"
				disabled={startPairing.isPending}
				onClick={() => void handleStart()}
			>
				{vi.telegram.startPairingButton}
			</Button>
			{startPairing.isError && (
				<p role="alert" className="text-sm font-semibold text-ink">
					{startPairing.error.status === 429
						? vi.login.tooMany
						: vi.common.saveError}
				</p>
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
