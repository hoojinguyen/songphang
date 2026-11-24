"use client";
import type { SessionClient } from "@songphang/contract";
import { useRevokeSession, useSessions } from "../../lib/auth";
import { vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { LoadError } from "../ui/LoadError";

function clientLabel(client: SessionClient): string {
	if (client === "ios") return vi.account.clientIos;
	if (client === "android") return vi.account.clientAndroid;
	return vi.account.clientWeb;
}

export function SessionsCard() {
	const sessions = useSessions();
	const revoke = useRevokeSession();

	if (sessions.isPending) {
		return <div aria-busy="true" className="h-32 rounded-[30px] bg-sunken" />;
	}
	if (sessions.isError && !sessions.data) {
		return (
			<LoadError
				isRetrying={sessions.isFetching}
				onRetry={() => {
					void sessions.refetch();
				}}
			/>
		);
	}
	return (
		<section className="grid gap-4 rounded-[30px] bg-surface p-5">
			<h2 className="font-extrabold">{vi.account.sessionsTitle}</h2>
			<ul className="grid gap-3">
				{sessions.data.map((session) => {
					const label = clientLabel(session.client);
					const title = session.deviceName ?? label;
					const subtitle = session.current
						? `${label} · ${vi.account.currentDevice}`
						: label;
					return (
						<li
							key={session.id}
							className="flex items-center justify-between gap-3 rounded-[20px] bg-bg px-4 py-3"
						>
							<div className="min-w-0">
								<p className="break-words text-sm font-bold text-ink">
									{title}
								</p>
								<p className="text-xs text-muted">{subtitle}</p>
							</div>
							<Button
								variant="surface"
								size="md"
								disabled={revoke.isPending}
								onClick={() =>
									revoke.mutate({ id: session.id, current: session.current })
								}
							>
								{vi.common.logout}
							</Button>
						</li>
					);
				})}
			</ul>
			{revoke.isError && <p role="alert">{vi.common.saveError}</p>}
		</section>
	);
}
