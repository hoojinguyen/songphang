"use client";
import type { GroupRole, TransactionDisputeDto } from "@songphang/contract";
import { useState } from "react";
import { useOpenDispute, useResolveDispute } from "../../lib/comments";
import { useOnline } from "../../lib/use-online";
import { t, vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { ConfirmDialog } from "../ui/ConfirmDialog";
import { useSnackbar } from "../ui/Snackbar";

export function DisputeBlock({
	groupId,
	transactionId,
	dispute,
	role,
	verified,
	deleted,
}: {
	groupId: string;
	transactionId: string;
	dispute: TransactionDisputeDto | null;
	role: GroupRole;
	verified: boolean;
	deleted: boolean;
}) {
	const [dialogOpen, setDialogOpen] = useState(false);
	const [reason, setReason] = useState("");
	const online = useOnline();
	const snackbar = useSnackbar();
	const openMutation = useOpenDispute(groupId, transactionId);
	const resolveMutation = useResolveDispute(groupId, transactionId);

	if (dispute) {
		const canResolve = verified && (dispute.mine || role === "owner");
		return (
			<section className="grid gap-3 rounded-[28px] bg-coral p-4 text-ink">
				<p className="text-sm font-extrabold">
					{t(vi.transactionView.disputedBy, { name: dispute.openedByName })}
				</p>
				<p className="whitespace-pre-wrap break-words text-sm">
					{dispute.reason}
				</p>
				{resolveMutation.isError && (
					<p role="alert" className="text-xs font-bold">
						{vi.common.saveError}
					</p>
				)}
				{canResolve && (
					<Button
						variant="primary"
						disabled={resolveMutation.isPending}
						onClick={() =>
							resolveMutation.mutate(undefined, {
								onSuccess: () =>
									snackbar({ text: vi.transactionView.disputeResolved }),
							})
						}
					>
						{vi.transactionView.resolveDispute}
					</Button>
				)}
			</section>
		);
	}

	if (deleted || !verified) return null;

	const trimmed = reason.trim();
	const submitOpen = () => {
		if (!trimmed || openMutation.isPending) return;
		openMutation.mutate(trimmed, {
			onSuccess: () => {
				setDialogOpen(false);
				setReason("");
			},
		});
	};

	return (
		<>
			<Button
				variant="surface"
				disabled={!online}
				onClick={() => setDialogOpen(true)}
				className="w-full"
			>
				{vi.transactionView.openDispute}
			</Button>
			{dialogOpen && (
				<ConfirmDialog
					title={vi.transactionView.disputeTitle}
					body=""
					confirmLabel={vi.transactionView.send}
					cancelLabel={vi.transactionView.disputeCancel}
					confirmDisabled={!trimmed || openMutation.isPending}
					onConfirm={submitOpen}
					onCancel={() => {
						if (!openMutation.isPending) setDialogOpen(false);
					}}
				>
					<label className="grid gap-1.5 text-xs font-semibold text-muted">
						{vi.transactionView.disputeReasonLabel}
						<textarea
							value={reason}
							maxLength={500}
							rows={3}
							onChange={(event) => setReason(event.target.value)}
							className="w-full rounded-[20px] bg-surface p-3 text-sm text-ink"
						/>
					</label>
					{openMutation.isError && (
						<p role="alert" className="mt-2 text-xs font-bold text-ink">
							{vi.common.saveError}
						</p>
					)}
				</ConfirmDialog>
			)}
		</>
	);
}
