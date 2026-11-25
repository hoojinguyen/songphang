"use client";
import { useState } from "react";
import {
	useCreateGroupChatLinkCode,
	useGroupChatLinks,
	useUnlinkGroupChat,
} from "../../lib/chat-links";
import { useFeatures } from "../../lib/features";
import { useSessionGuard } from "../../lib/use-session-guard";
import { t, vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { LoadError } from "../ui/LoadError";

export function TelegramCard({
	groupId,
	disabled = false,
}: {
	groupId: string;
	disabled?: boolean;
}) {
	const features = useFeatures();
	const telegramEnabled = features.data?.telegram === true;
	const links = useGroupChatLinks(groupId, telegramEnabled);
	const createCode = useCreateGroupChatLinkCode(groupId);
	const unlink = useUnlinkGroupChat(groupId);
	const [copied, setCopied] = useState(false);

	useSessionGuard(links.error ?? createCode.error ?? unlink.error ?? null);

	if (!telegramEnabled) return null;
	if (links.isPending) {
		return <div aria-busy="true" className="h-32 rounded-[28px] bg-sunken" />;
	}
	if (links.isError) {
		return (
			<LoadError
				onRetry={() => {
					void links.refetch();
				}}
				isRetrying={links.isFetching}
			/>
		);
	}

	const botUsername =
		createCode.data?.botUsername ?? links.data.botUsername ?? "";
	const command = createCode.data?.command;

	async function copyCommand() {
		if (!command) return;
		try {
			await navigator.clipboard.writeText(command);
			setCopied(true);
		} catch {
			setCopied(false);
		}
	}

	return (
		<section className="grid gap-3 rounded-[28px] bg-surface p-5">
			<h2 className="font-extrabold">{vi.telegram.settingsTitle}</h2>
			<p className="text-xs text-muted">
				{t(vi.telegram.settingsHint, { bot: botUsername })}
			</p>
			<Button
				variant="surface"
				className="h-12 bg-bg"
				disabled={disabled || createCode.isPending}
				onClick={() => {
					setCopied(false);
					createCode.mutate();
				}}
			>
				{vi.telegram.generateCode}
			</Button>
			{command && (
				<div className="grid gap-2 rounded-[20px] bg-sunken p-3">
					<div className="flex items-center justify-between gap-2">
						<code className="min-w-0 break-all font-mono text-sm font-bold text-ink">
							{command}
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
			)}
			{links.data.chatLinks.length > 0 && (
				<ul className="grid gap-2">
					{links.data.chatLinks.map((link) => (
						<li
							key={link.id}
							className="flex items-center justify-between gap-2 rounded-[20px] bg-bg px-3 py-2"
						>
							<span className="min-w-0 break-all font-mono text-xs text-ink">
								{link.chatId}
							</span>
							<button
								type="button"
								disabled={disabled || unlink.isPending}
								onClick={() => unlink.mutate(link.id)}
								className="min-h-11 shrink-0 rounded-pill bg-surface px-3 text-xs font-bold text-ink disabled:opacity-60"
							>
								{vi.telegram.unlink}
							</button>
						</li>
					))}
				</ul>
			)}
			{(createCode.isError || unlink.isError) && (
				<p role="alert" className="text-sm text-coral">
					{(createCode.error ?? unlink.error)?.status === 403
						? vi.common.forbidden
						: vi.common.saveError}
				</p>
			)}
		</section>
	);
}
