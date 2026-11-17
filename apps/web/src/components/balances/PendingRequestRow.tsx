"use client";
import { useQueryClient } from "@tanstack/react-query";
import { useRef } from "react";
import { formatMoney } from "../../lib/money";
import { useResolveSettlementRequest } from "../../lib/settlement-requests";
import { useSessionGuard } from "../../lib/use-session-guard";
import { t, vi } from "../../messages/vi";
import { Button } from "../ui/Button";
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
	request: { id: string; amount: number; createdByMe: boolean };
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
			<p className="text-sm font-bold text-ink">
				{canResolve
					? t(vi.pay.pendingConfirmText, {
							from: fromName,
							amount: formatMoney(request.amount),
						})
					: t(vi.pay.pendingWaiting, { to: toName })}
			</p>
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
		</div>
	);
}
