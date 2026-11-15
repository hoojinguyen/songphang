"use client";
import { useChangeInvite, useInvite } from "../../lib/invites";
import { useSessionGuard } from "../../lib/use-session-guard";
import { vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { LoadError } from "../ui/LoadError";
export function InviteLinkCard({ groupId }: { groupId: string }) {
	const invite = useInvite(groupId);
	const change = useChangeInvite(groupId);
	useSessionGuard(invite.error ?? change.error);
	if (invite.isPending)
		return <div aria-busy="true" className="h-40 rounded-card bg-sunken" />;
	if (invite.isError)
		return (
			<LoadError
				onRetry={() => {
					void invite.refetch();
				}}
				isRetrying={invite.isFetching}
			/>
		);
	return (
		<section className="grid gap-3 rounded-[28px] bg-surface p-5">
			<h2 className="font-extrabold">{vi.settings.linkTitle}</h2>
			<p className="text-xs text-muted">
				{invite.data.active ? vi.settings.linkOn : vi.settings.linkOff}
			</p>
			<Button
				variant="surface"
				className="h-12 bg-bg"
				disabled={change.isPending}
				onClick={() => change.mutate({ active: !invite.data.active })}
			>
				{invite.data.active ? vi.settings.disableLink : vi.settings.enableLink}
			</Button>
			<Button
				variant="surface"
				className="h-12 bg-bg"
				disabled={change.isPending}
				onClick={() => change.mutate({ rotate: true })}
			>
				{vi.settings.rotateLink}
			</Button>
			{change.isError && (
				<p role="alert">
					{change.error.status === 403
						? vi.common.forbidden
						: vi.common.saveError}
				</p>
			)}
		</section>
	);
}
