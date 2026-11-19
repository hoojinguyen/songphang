"use client";
import {
	useMyChatIdentities,
	useUnlinkChatIdentity,
} from "../../lib/chat-links";
import { useFeatures } from "../../lib/features";
import { useSessionGuard } from "../../lib/use-session-guard";
import { t, vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { LoadError } from "../ui/LoadError";

export function TelegramIdentityCard() {
	const features = useFeatures();
	const telegramEnabled = features.data?.telegram === true;
	const identities = useMyChatIdentities(telegramEnabled);
	const unlink = useUnlinkChatIdentity();
	useSessionGuard(identities.error ?? unlink.error);

	if (!telegramEnabled) return null;
	if (identities.isPending) {
		return <div aria-busy="true" className="h-24 rounded-[30px] bg-sunken" />;
	}
	if (identities.isError && !identities.data) {
		return (
			<LoadError
				isRetrying={identities.isFetching}
				onRetry={() => {
					void identities.refetch();
				}}
			/>
		);
	}

	const telegram = identities.data.chatIdentities.find(
		(item) => item.platform === "telegram",
	);
	if (!telegram) return null;

	return (
		<section className="grid gap-3 rounded-[30px] bg-surface p-5">
			<h2 className="font-extrabold">{vi.telegram.accountTitle}</h2>
			<p className="text-sm font-semibold text-ink">
				{t(vi.telegram.accountLinked, { name: vi.telegram.accountTitle })}
			</p>
			<Button
				variant="surface"
				size="md"
				className="bg-bg"
				disabled={unlink.isPending}
				onClick={() => unlink.mutate("telegram")}
			>
				{vi.telegram.unlink}
			</Button>
			{unlink.isError && <p role="alert">{vi.common.saveError}</p>}
		</section>
	);
}
