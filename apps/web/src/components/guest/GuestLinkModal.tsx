"use client";
import { useEffect, useId, useRef, useState } from "react";
import {
	useEnableGuestLink,
	useGuestLink,
	useRevokeGuestLink,
} from "../../lib/guest-links";
import { useSessionGuard } from "../../lib/use-session-guard";
import { vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { Icon } from "../ui/Icon";
import { LoadError } from "../ui/LoadError";
import { useSnackbar } from "../ui/Snackbar";

export function GuestLinkModal({
	open,
	groupId,
	isArchived,
	onClose,
}: {
	open: boolean;
	groupId: string;
	isArchived: boolean;
	onClose: () => void;
}) {
	const dialogRef = useRef<HTMLDialogElement>(null);
	const titleId = useId();
	const [confirmRotate, setConfirmRotate] = useState(false);
	const showNotice = useSnackbar();

	const guestLink = useGuestLink(groupId, open);
	const enableMutation = useEnableGuestLink(groupId);
	const revokeMutation = useRevokeGuestLink(groupId);
	useSessionGuard(
		guestLink.error ?? enableMutation.error ?? revokeMutation.error,
	);

	useEffect(() => {
		const dialog = dialogRef.current;
		if (!dialog) return;
		dialog.setAttribute("closedby", "any");
		if (open && !dialog.open) {
			setConfirmRotate(false);
			dialog.showModal();
		} else if (!open && dialog.open) {
			dialog.close();
		}
	}, [open]);

	const linkData = guestLink.data;
	const busy = enableMutation.isPending || revokeMutation.isPending;

	const copyUrl = async (url: string) => {
		try {
			await navigator.clipboard.writeText(url);
			showNotice({ text: vi.guestLink.copied });
		} catch {
			showNotice({ text: vi.common.saveError });
		}
	};

	return (
		<dialog
			ref={dialogRef}
			aria-labelledby={titleId}
			onClose={onClose}
			className="m-auto w-[calc(100%-32px)] max-w-[410px] rounded-[30px] bg-bg p-5 text-ink backdrop:bg-ink/40"
		>
			<div className="grid gap-4">
				<div className="flex items-center justify-between gap-2">
					<h2 id={titleId} className="text-lg font-black">
						{vi.guestLink.fullTitle}
					</h2>
					<button
						type="button"
						aria-label={vi.common.cancel}
						onClick={onClose}
						className="flex h-11 w-11 items-center justify-center rounded-full bg-surface text-ink"
					>
						<Icon name="close" size={18} />
					</button>
				</div>

				<p className="rounded-[20px] bg-sunken p-3.5 text-xs font-semibold text-muted">
					{vi.guestLink.description}
				</p>

				{guestLink.isPending ? (
					<div aria-busy="true" className="h-24 rounded-[20px] bg-sunken" />
				) : guestLink.isError ? (
					<LoadError
						onRetry={() => {
							void guestLink.refetch();
						}}
						isRetrying={guestLink.isFetching}
					/>
				) : linkData?.active && linkData.url ? (
					<div className="grid gap-3">
						<div className="rounded-[18px] bg-surface p-3 text-xs font-semibold break-all text-ink">
							{linkData.url}
						</div>

						<Button
							variant="accent"
							allowOffline
							onClick={() => {
								if (linkData.url) void copyUrl(linkData.url);
							}}
						>
							{vi.guestLink.copyAction}
						</Button>

						{!isArchived &&
							(confirmRotate ? (
								<div className="grid gap-2 rounded-[20px] bg-surface p-3">
									<p className="text-xs font-bold text-ink">
										{vi.settings.linkOn}
									</p>
									<div className="flex gap-2">
										<Button
											variant="surface"
											allowOffline
											className="flex-1 bg-sunken text-xs"
											onClick={() => setConfirmRotate(false)}
										>
											{vi.common.cancel}
										</Button>
										<Button
											variant="primary"
											className="flex-1 text-xs"
											disabled={busy}
											onClick={() => {
												enableMutation.mutate(
													{ rotate: true },
													{
														onSuccess: () => setConfirmRotate(false),
													},
												);
											}}
										>
											{vi.guestLink.rotateAction}
										</Button>
									</div>
								</div>
							) : (
								<Button
									variant="surface"
									disabled={busy}
									onClick={() => setConfirmRotate(true)}
								>
									{vi.guestLink.rotateAction}
								</Button>
							))}

						<Button
							variant="surface"
							className="bg-debt-soft text-ink"
							disabled={busy}
							onClick={() => revokeMutation.mutate()}
						>
							{vi.guestLink.revokeAction}
						</Button>
					</div>
				) : (
					<div className="grid gap-3">
						{isArchived ? (
							<p className="text-xs font-bold text-muted">
								{vi.groups.archivedReadOnlyError}
							</p>
						) : (
							<Button
								variant="accent"
								disabled={busy}
								onClick={() => enableMutation.mutate({})}
							>
								{vi.guestLink.enableAction}
							</Button>
						)}
					</div>
				)}

				{(enableMutation.isError || revokeMutation.isError) && (
					<p role="alert" className="text-xs font-bold text-debt">
						{(enableMutation.error ?? revokeMutation.error)?.status === 403
							? vi.common.forbidden
							: vi.common.saveError}
					</p>
				)}
			</div>
		</dialog>
	);
}
