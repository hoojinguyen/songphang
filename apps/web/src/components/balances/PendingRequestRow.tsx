"use client";
import type { PaymentChannel } from "@songphang/contract";
import { useQueryClient } from "@tanstack/react-query";
import { useRef, useState } from "react";
import { attachmentContentUrl } from "../../lib/attachments";
import { formatMoney } from "../../lib/money";
import { useResolveSettlementRequest } from "../../lib/settlement-requests";
import { useSessionGuard } from "../../lib/use-session-guard";
import { t, vi } from "../../messages/vi";
import { paymentChannelLabel } from "../pay/TransferProofFields";
import { Button } from "../ui/Button";
import { PhotoViewer } from "../ui/PhotoViewer";
import { useSnackbar } from "../ui/Snackbar";

export function PendingRequestRow({
	groupId,
	request,
	fromName,
	toName,
	canResolve,
	canCancel,
	verified,
}: {
	groupId: string;
	request: {
		id: string;
		amount: number;
		createdByMe: boolean;
		channel?: PaymentChannel | null | undefined;
		note?: string | null | undefined;
		proofAttachmentId?: string | null | undefined;
	};
	fromName: string;
	toName: string;
	canResolve: boolean;
	canCancel: boolean;
	verified: boolean;
}) {
	const resolve = useResolveSettlementRequest(groupId);
	const snackbar = useSnackbar();
	const client = useQueryClient();
	const sendingRef = useRef(false);
	const [viewingProof, setViewingProof] = useState(false);
	useSessionGuard(resolve.error);

	function submit(action: "confirm" | "reject" | "cancel") {
		if (!verified || sendingRef.current) return;
		sendingRef.current = true;
		resolve.mutate(
			{ id: request.id, action },
			{
				onSuccess: () => {
					if (action === "confirm") {
						snackbar({
							text: t(vi.pay.confirmedNotice, {
								amount: formatMoney(request.amount),
								from: fromName,
							}),
						});
					} else if (action === "reject") {
						snackbar({ text: vi.pay.rejectedNotice });
					}
				},
				onError: (error) => {
					if (error.status === 409) {
						snackbar({ text: vi.pay.alreadyResolved });
						void client.invalidateQueries({
							queryKey: ["group", groupId, "balances"],
						});
						void client.invalidateQueries({
							queryKey: ["group", groupId, "settlementRequests"],
						});
					}
				},
				onSettled: () => {
					sendingRef.current = false;
				},
			},
		);
	}

	return (
		<div className="grid w-full gap-2 rounded-[22px] bg-sunken p-3">
			<div className="flex items-start justify-between gap-3">
				<div className="min-w-0 flex-1 grid gap-1">
					<p className="text-sm font-bold text-ink">
						{canResolve
							? t(vi.pay.pendingConfirmText, {
									from: fromName,
									amount: formatMoney(request.amount),
								})
							: t(vi.pay.pendingWaiting, { to: toName })}
					</p>
					{(request.channel || request.note) && (
						<div className="flex flex-wrap items-center gap-1.5 text-xs text-muted">
							{request.channel && (
								<span className="rounded-pill bg-surface px-2 py-0.5 text-[11px] font-bold text-ink">
									{paymentChannelLabel(request.channel)}
								</span>
							)}
							{request.note && (
								<span className="break-words font-semibold text-ink">
									{`“${request.note}”`}
								</span>
							)}
						</div>
					)}
				</div>
				{request.proofAttachmentId && (
					<button
						type="button"
						aria-label={vi.settlementProof.viewProof}
						onClick={() => setViewingProof(true)}
						className="flex h-11 w-11 shrink-0 items-center justify-center rounded-[12px] bg-surface p-0.5"
					>
						<img
							src={attachmentContentUrl(groupId, request.proofAttachmentId)}
							alt={vi.settlementProof.viewProof}
							className="h-10 w-10 rounded-[10px] object-cover"
						/>
					</button>
				)}
			</div>
			<div className="flex flex-wrap gap-2">
				{canResolve && (
					<>
						<Button
							variant="accent"
							className="flex-1"
							disabled={!verified || resolve.isPending}
							onClick={() => submit("confirm")}
						>
							{vi.balances.received}
						</Button>
						<Button
							variant="surface"
							className="flex-1"
							disabled={!verified || resolve.isPending}
							onClick={() => submit("reject")}
						>
							{vi.pay.rejectReceived}
						</Button>
					</>
				)}
				{canCancel && (
					<Button
						variant="surface"
						className={canResolve ? "" : "flex-1"}
						disabled={!verified || resolve.isPending}
						onClick={() => submit("cancel")}
					>
						{vi.pay.cancelReport}
					</Button>
				)}
			</div>
			{resolve.isError && resolve.error.status !== 409 && (
				<p role="alert" className="text-xs text-ink">
					{resolve.error.status === 403
						? vi.common.forbidden
						: vi.common.saveError}
				</p>
			)}
			{viewingProof && request.proofAttachmentId && (
				<PhotoViewer
					src={attachmentContentUrl(groupId, request.proofAttachmentId)}
					alt={vi.settlementProof.viewProof}
					onClose={() => setViewingProof(false)}
				/>
			)}
		</div>
	);
}
