"use client";
import type { BalancesResponse, MemberDto } from "@songphang/contract";
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
const MAX_TRANSFER_AMOUNT = 999_999_999_999;

export function PayFooter({
	groupId,
	from,
	to,
	transfer,
	mayCreate,
	canEdit,
	canResolve,
	canCancel,
	verified,
}: {
	groupId: string;
	from: MemberDto;
	to: MemberDto;
	transfer: Transfer;
	mayCreate: boolean;
	canEdit: boolean;
	canResolve: boolean;
	canCancel: boolean;
	verified: boolean;
}) {
	const router = useRouter();
	const snackbar = useSnackbar();
	const client = useQueryClient();
	const [idempotencyKey] = useState(() => crypto.randomUUID());
	const sendingRef = useRef(false);
	const createRequest = useCreateSettlementRequest(groupId);
	useSessionGuard(createRequest.error);

	function submitReport() {
		if (!verified || sendingRef.current) return;
		sendingRef.current = true;
		createRequest.mutate(
			{
				key: idempotencyKey,
				request: {
					fromMemberId: from.id,
					toMemberId: to.id,
					amount: Math.min(transfer.amount, MAX_TRANSFER_AMOUNT),
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
								disabled={createRequest.isPending}
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
