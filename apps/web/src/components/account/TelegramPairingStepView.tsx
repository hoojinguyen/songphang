"use client";
import type {
	StartTelegramPairingResponse,
	TelegramPairingDto,
} from "@songphang/contract";
import Link from "next/link";
import { useState } from "react";
import { t, vi } from "../../messages/vi";
import { Button } from "../ui/Button";

function formatTelegramIdentity(
	platformName: string | null,
	platformUserId: string | null,
): string {
	if (platformName && platformUserId) {
		return `${platformName} (ID #${platformUserId})`;
	}
	if (platformUserId) {
		return `ID #${platformUserId}`;
	}
	return vi.telegram.accountTitle;
}

export function TelegramPairingStepView({
	started,
	pairing,
	email,
	isConfirmPending,
	isCancelPending,
	errorMessage,
	onConfirm,
	onCancel,
}: {
	started: StartTelegramPairingResponse;
	pairing: TelegramPairingDto;
	email: string;
	isConfirmPending: boolean;
	isCancelPending: boolean;
	errorMessage: string | null;
	onConfirm: () => void;
	onCancel: () => void;
}) {
	const [copied, setCopied] = useState(false);
	const telegramIdentity = formatTelegramIdentity(
		pairing.stagedPlatformName,
		pairing.stagedPlatformUserId,
	);

	async function copyCommand() {
		try {
			await navigator.clipboard.writeText(started.startCommand);
			setCopied(true);
		} catch {
			setCopied(false);
		}
	}

	if (pairing.status === "telegram_confirmed") {
		return (
			<main className="mx-auto grid min-h-dvh max-w-[430px] content-center gap-5 px-5 py-6">
				<h1 className="break-words text-[24px] font-black">
					{vi.telegram.confirmStepTitle}
				</h1>
				<p className="break-words text-sm text-ink">
					{t(vi.telegram.confirmStepBody, { telegramIdentity, email })}
				</p>
				<Button
					variant="primary"
					size="lg"
					disabled={isConfirmPending || isCancelPending}
					onClick={onConfirm}
				>
					{vi.telegram.finalConfirmButton}
				</Button>
				<Button
					variant="surface"
					size="md"
					disabled={isConfirmPending || isCancelPending}
					onClick={onCancel}
				>
					{vi.telegram.cancelPairingButton}
				</Button>
				{errorMessage && (
					<p role="alert" className="text-sm font-semibold text-ink">
						{errorMessage}
					</p>
				)}
			</main>
		);
	}

	const botUsername = pairing.botUsername;
	return (
		<main className="mx-auto grid min-h-dvh max-w-[430px] content-center gap-5 px-5 py-6">
			<h1 className="text-[24px] font-black">{vi.telegram.privateStepTitle}</h1>
			<p className="text-sm text-muted">
				{botUsername
					? t(vi.telegram.privateStepHint, { bot: botUsername })
					: vi.telegram.privateStepHintNoBot}
			</p>
			{started.deepLinkUrl && botUsername && (
				<a
					href={started.deepLinkUrl}
					target="_blank"
					rel="noopener noreferrer"
					className="flex min-h-12 items-center justify-center rounded-pill bg-ink px-6 font-bold text-surface"
				>
					{t(vi.telegram.openTelegramButton, { bot: botUsername })}
				</a>
			)}
			<div className="grid gap-2 rounded-[20px] bg-sunken p-4">
				<div className="flex items-center justify-between gap-2">
					<code className="min-w-0 break-all font-mono text-sm font-bold text-ink">
						{started.startCommand}
					</code>
					<button
						type="button"
						onClick={() => void copyCommand()}
						className="min-h-11 shrink-0 rounded-pill bg-surface px-4 text-xs font-bold text-ink"
					>
						{copied ? vi.telegram.copied : vi.telegram.copy}
					</button>
				</div>
				<p className="text-xs text-muted">{vi.telegram.codeTtl}</p>
			</div>
			<p className="text-sm font-semibold text-ink">
				{pairing.stagedPlatformUserId
					? t(vi.telegram.stagedWaitingConfirm, { telegramIdentity })
					: vi.telegram.waitingForTelegram}
			</p>
			<Button
				variant="surface"
				size="md"
				disabled={isCancelPending}
				onClick={onCancel}
			>
				{vi.telegram.cancelPairingButton}
			</Button>
			{errorMessage && (
				<p role="alert" className="text-sm font-semibold text-ink">
					{errorMessage}
				</p>
			)}
			<Link
				href="/"
				className="flex min-h-11 items-center justify-center rounded-pill bg-surface px-6 text-sm font-bold text-ink"
			>
				{vi.common.backToGroups}
			</Link>
		</main>
	);
}
