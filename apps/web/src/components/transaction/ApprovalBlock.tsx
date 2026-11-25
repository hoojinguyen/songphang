"use client";
import type { GroupRole, TransactionApprovalDto } from "@songphang/contract";
import { useState } from "react";
import {
	useApproveTransaction,
	useRejectTransaction,
} from "../../lib/transaction-changes";
import { useOnline } from "../../lib/use-online";
import { t, vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { ConfirmDialog } from "../ui/ConfirmDialog";

export function ApprovalBlock({
	groupId,
	transactionId,
	approval,
	ownerName,
	role,
	verified,
	deleted,
}: {
	groupId: string;
	transactionId: string;
	approval: TransactionApprovalDto;
	ownerName: string;
	role: GroupRole;
	verified: boolean;
	deleted: boolean;
}) {
	const [rejectOpen, setRejectOpen] = useState(false);
	const [note, setNote] = useState("");
	const online = useOnline();
	const approveMutation = useApproveTransaction(groupId, transactionId);
	const rejectMutation = useRejectTransaction(groupId, transactionId);

	if (deleted || approval.status === "none" || approval.status === "approved") {
		return null;
	}

	if (approval.status === "rejected") {
		return (
			<section className="grid gap-2 rounded-[28px] bg-coral p-4 text-on-accent">
				<p className="text-sm font-extrabold">
					{t(vi.approval.rejectedTitle, { owner: ownerName })}
				</p>
				{approval.note && (
					<p className="whitespace-pre-wrap break-words text-sm">
						{approval.note}
					</p>
				)}
			</section>
		);
	}

	const canDecide = role === "owner" && verified;
	const busy = approveMutation.isPending || rejectMutation.isPending;

	return (
		<>
			<section className="grid gap-3 rounded-[28px] bg-accent p-4 text-on-accent">
				<p className="text-sm font-extrabold">
					{t(vi.approval.pendingBanner, { owner: ownerName })}
				</p>
				{approveMutation.isError && (
					<p role="alert" className="text-xs font-bold">
						{approveMutation.error.status === 403
							? vi.common.forbidden
							: vi.common.saveError}
					</p>
				)}
				{canDecide && (
					<div className="flex flex-wrap gap-2">
						<Button
							variant="primary"
							disabled={!online || busy}
							onClick={() => approveMutation.mutate()}
							className="flex-1"
						>
							{vi.approval.approve}
						</Button>
						<Button
							variant="surface"
							disabled={!online || busy}
							onClick={() => setRejectOpen(true)}
							className="flex-1"
						>
							{vi.approval.reject}
						</Button>
					</div>
				)}
			</section>
			{rejectOpen && (
				<ConfirmDialog
					title={vi.approval.rejectTitle}
					body=""
					confirmLabel={vi.approval.reject}
					cancelLabel={vi.approval.rejectCancel}
					confirmDisabled={!online || busy}
					onConfirm={() =>
						rejectMutation.mutate(note, {
							onSuccess: () => {
								setRejectOpen(false);
								setNote("");
							},
						})
					}
					onCancel={() => {
						if (!busy) setRejectOpen(false);
					}}
				>
					<label className="grid gap-1.5 text-xs font-semibold text-muted">
						{vi.approval.rejectNoteLabel}
						<textarea
							value={note}
							maxLength={300}
							rows={3}
							onChange={(event) => setNote(event.target.value)}
							className="w-full rounded-[20px] bg-surface p-3 text-sm text-ink"
						/>
					</label>
					{rejectMutation.isError && (
						<p role="alert" className="mt-2 text-xs font-bold text-ink">
							{rejectMutation.error.status === 403
								? vi.common.forbidden
								: vi.common.saveError}
						</p>
					)}
				</ConfirmDialog>
			)}
		</>
	);
}
