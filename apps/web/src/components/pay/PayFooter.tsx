"use client";
import type {
	BalancesResponse,
	MemberDto,
	PaymentChannel,
} from "@songphang/contract";
import { useQueryClient } from "@tanstack/react-query";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useRef, useState } from "react";
import { settlementHref } from "../../lib/balances";
import { useCreateSettlementRequest } from "../../lib/settlement-requests";
import { useSessionGuard } from "../../lib/use-session-guard";
import { t, vi } from "../../messages/vi";
import { PendingRequestRow } from "../balances/PendingRequestRow";
import { Button } from "../ui/Button";
import { useSnackbar } from "../ui/Snackbar";
import { VerifyEmailBanner } from "../ui/VerifyEmailBanner";

type Transfer = BalancesResponse["transfers"][number];

export function PayFooter({
	groupId,
	from,
	to,
	transfer,
	payAmount,
	mayCreate,
	canEdit,
	canResolve,
	canCancel,
	verified,
	channel,
	note,
	proofAttachmentId,
	uploadingProof = false,
}: {
	groupId: string;
	from: MemberDto;
	to: MemberDto;
	transfer: Transfer;
	payAmount: number;
	mayCreate: boolean;
	canEdit: boolean;
	canResolve: boolean;
	canCancel: boolean;
	verified: boolean;
	channel?: PaymentChannel | null;
	note?: string;
	proofAttachmentId?: string | null;
	uploadingProof?: boolean;
}) {
	const router = useRouter();
	const snackbar = useSnackbar();
	const client = useQueryClient();
	const [idempotencyKey] = useState(() => crypto.randomUUID());
	const sendingRef = useRef(false);
	const createRequest = useCreateSettlementRequest(groupId);
	useSessionGuard(createRequest.error);

	function submitReport() {
		if (!verified || sendingRef.current || uploadingProof) return;
		sendingRef.current = true;
		const trimmedNote = note?.trim();
		createRequest.mutate(
			{
				key: idempotencyKey,
				request: {
					fromMemberId: from.id,
					toMemberId: to.id,
					amount: payAmount,
					...(channel ? { channel } : {}),
					...(trimmedNote ? { note: trimmedNote } : {}),
					...(proofAttachmentId ? { proofAttachmentId } : {}),
				},
			},
			{
				onSuccess: () => {
					snackbar({ text: t(vi.pay.reportedNotice, { to: to.name }) });
					router.replace(`/g/${groupId}/balances`);
				},
				onError: (err) => {
					if (err.status === 409) {
						snackbar({ text: vi.pay.alreadyResolved });
						void client.invalidateQueries({
							queryKey: ["group", groupId, "balances"],
						});
						router.replace(`/g/${groupId}/balances`);
					}
				},
				onSettled: () => {
					sendingRef.current = false;
				},
			},
		);
	}

	return (
		<div className="sticky bottom-0 -mx-5 mt-auto grid gap-2 bg-bg/95 px-5 pt-3 pb-4">
			{transfer.pendingRequest ? (
				<PendingRequestRow
					groupId={groupId}
					request={transfer.pendingRequest}
					fromName={from.name}
					toName={to.name}
					canResolve={canResolve}
					canCancel={canCancel}
					verified={verified}
				/>
			) : (
				<>
					{canEdit && (
						<Link
							href={settlementHref(groupId, transfer)}
							className="flex min-h-11 items-center justify-center text-sm font-bold text-ink underline"
						>
							{vi.pay.recordDirect}
						</Link>
					)}
					{createRequest.isError && createRequest.error.status !== 409 && (
						<p role="alert" className="text-center text-xs text-ink">
							{createRequest.error.status === 403
								? vi.common.forbidden
								: vi.common.saveError}
						</p>
					)}
					{mayCreate &&
						(verified ? (
							<Button
								variant="primary"
								size="lg"
								className="w-full"
								disabled={createRequest.isPending || uploadingProof}
								onClick={submitReport}
							>
								{vi.pay.reportedButton}
							</Button>
						) : (
							<VerifyEmailBanner />
						))}
				</>
			)}
		</div>
	);
}
