"use client";
import { create } from "qrcode";
import { useEffect, useMemo, useState } from "react";
import { useInvite } from "../../lib/invites";
import { useSessionGuard } from "../../lib/use-session-guard";
import { vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { LoadError } from "../ui/LoadError";

function InviteQr({ url }: { url: string }) {
	const matrix = useMemo(
		() => create(url, { errorCorrectionLevel: "M" }).modules,
		[url],
	);
	const path = Array.from(matrix.data, (value, index) =>
		value
			? `M${(index % matrix.size) + 4} ${Math.floor(index / matrix.size) + 4}h1v1h-1z`
			: "",
	).join("");
	return (
		<svg
			role="img"
			aria-label={vi.invite.qrLabel}
			width="96"
			height="96"
			viewBox={`0 0 ${matrix.size + 8} ${matrix.size + 8}`}
			className="bg-surface text-ink"
			shapeRendering="crispEdges"
		>
			<title>{vi.invite.qrLabel}</title>
			<path d={path} fill="currentColor" />
		</svg>
	);
}
export function InviteCard({ groupId }: { groupId: string }) {
	const invite = useInvite(groupId);
	const [copied, setCopied] = useState(false);
	const [error, setError] = useState(false);
	const [canShare, setCanShare] = useState(false);
	useSessionGuard(invite.error);
	useEffect(() => setCanShare(typeof navigator.share === "function"), []);
	useEffect(() => {
		if (!copied) return;
		const timer = setTimeout(() => setCopied(false), 2000);
		return () => clearTimeout(timer);
	}, [copied]);
	if (invite.isPending)
		return <div aria-busy="true" className="h-40 rounded-[36px] bg-sunken" />;
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
		<section className="grid gap-3 rounded-[36px] bg-accent p-4 text-on-accent">
			<div className="flex items-center gap-4">
				{invite.data.active && (
					<div className="rounded-[22px] bg-surface p-2.5">
						<InviteQr url={invite.data.url} />
					</div>
				)}
				<div>
					<h2 className="text-[22px] font-black">{vi.invite.title}</h2>
					<p className="text-[13px] font-semibold">
						{invite.data.active ? vi.invite.hint : vi.invite.disabled}
					</p>
				</div>
			</div>
			{invite.data.active && (
				<div className="flex gap-3">
					<Button
						variant="primary"
						onClick={() => {
							setError(false);
							navigator.clipboard
								.writeText(invite.data.url)
								.then(() => setCopied(true))
								.catch(() => setError(true));
						}}
					>
						{vi.invite.copy}
					</Button>
					{canShare && (
						<Button
							variant="surface"
							onClick={() => {
								setError(false);
								navigator
									.share({ url: invite.data.url })
									.catch((reason: unknown) => {
										if (
											!(
												reason instanceof DOMException &&
												reason.name === "AbortError"
											)
										)
											setError(true);
									});
							}}
						>
							{vi.invite.share}
						</Button>
					)}
				</div>
			)}
			{copied && <p role="status">{vi.invite.copied}</p>}
			{error && <p role="alert">{vi.common.saveError}</p>}
		</section>
	);
}
