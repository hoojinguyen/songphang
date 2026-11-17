"use client";
import type { BalancesResponse, MemberDto } from "@songphang/contract";
import { useQueryClient } from "@tanstack/react-query";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useRef, useState } from "react";
import { settlementHref } from "../../lib/balances";
import { formatMoney } from "../../lib/money";
import { useCreateSettlementRequest } from "../../lib/settlement-requests";
import { useSessionGuard } from "../../lib/use-session-guard";
import { t, vi } from "../../messages/vi";
import { PendingRequestRow } from "../balances/PendingRequestRow";
import { Button } from "../ui/Button";
import { Icon } from "../ui/Icon";
import { MemberShape } from "../ui/MemberShape";
import { ScreenHeader } from "../ui/ScreenHeader";
import { useSnackbar } from "../ui/Snackbar";
import { VerifyEmailBanner } from "../ui/VerifyEmailBanner";
import { CopyRow } from "./CopyRow";
import { PayMethodsCard } from "./PayMethodsCard";

type Transfer = BalancesResponse["transfers"][number];

export function PayContent({
	groupId,
	from,
	to,
	transfer,
	myMemberId,
	role,
	verified,
}: {
	groupId: string;
	from: MemberDto;
	to: MemberDto;
	transfer: Transfer;
	myMemberId: string | null;
	role: "owner" | "editor" | "viewer";
	verified: boolean;
}) {
	const router = useRouter();
	const snackbar = useSnackbar();
	const client = useQueryClient();
	const [idempotencyKey] = useState(() => crypto.randomUUID());
	const sendingRef = useRef(false);
	const createRequest = useCreateSettlementRequest(groupId);
	useSessionGuard(createRequest.error);

	const mayCreate = role !== "viewer" || myMemberId === from.id;
	const canEdit = verified && role !== "viewer";
	const canAddDetails = verified && (role !== "viewer" || myMemberId === to.id);
	const canResolve =
		role === "owner" ||
		myMemberId === to.id ||
		(role === "editor" && !to.claimed);
	const canCancel =
		Boolean(transfer.pendingRequest?.createdByMe) || myMemberId === from.id;

	function submitReport() {
		if (!verified || sendingRef.current) return;
		sendingRef.current = true;
		createRequest.mutate(
			{
				key: idempotencyKey,
				request: {
					fromMemberId: from.id,
					toMemberId: to.id,
					amount: transfer.amount,
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
		<main className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-5 px-5 py-6 pb-28">
			<ScreenHeader
				title={t(vi.pay.title, { to: to.name })}
				backHref={`/g/${groupId}/balances`}
				backLabel={vi.common.back}
			/>
			<div className="flex items-center justify-around rounded-[36px] bg-surface p-4">
				{[from, to].map((member, index) => (
					<div key={member.id} className="flex items-center gap-3">
						<div className="grid justify-items-center gap-2">
							<MemberShape {...member} size={56} />
							<span className="text-sm font-extrabold">
								{member.id === myMemberId ? vi.common.you : member.name}
							</span>
						</div>
						{index === 0 && <Icon name="arrow-right" size={20} />}
					</div>
				))}
			</div>
			<div className="grid justify-items-center gap-2 text-center">
				<p className="text-[40px] font-black tracking-tight">
					{formatMoney(transfer.amount)}
				</p>
				<CopyRow
					label={vi.pay.copyAmount}
					value={formatMoney(transfer.amount)}
					copyValue={String(transfer.amount)}
					buttonLabel={vi.pay.copyAmount}
					compact
				/>
			</div>
			<PayMethodsCard
				groupId={groupId}
				transfer={transfer}
				toName={to.name}
				canAddDetails={canAddDetails}
			/>
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
		</main>
	);
}
