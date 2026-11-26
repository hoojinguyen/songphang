"use client";
import type {
	AttachmentDto,
	BalancesResponse,
	MemberDto,
	PaymentChannel,
} from "@songphang/contract";
import { useState } from "react";
import { formatMoney } from "../../lib/money";
import { t, vi } from "../../messages/vi";
import { Icon } from "../ui/Icon";
import { MemberShape } from "../ui/MemberShape";
import { ScreenHeader } from "../ui/ScreenHeader";
import { CopyRow } from "./CopyRow";
import { PayFooter } from "./PayFooter";
import { PayMethodsCard } from "./PayMethodsCard";
import { TransferProofFields } from "./TransferProofFields";

type Transfer = BalancesResponse["transfers"][number];
const MAX_TRANSFER_AMOUNT = 999_999_999_999;

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
	const isFromSide =
		myMemberId !== null &&
		(myMemberId === from.id ||
			Boolean(transfer.fromHousehold?.memberIds.includes(myMemberId)));
	const mayCreate = role !== "viewer" || isFromSide;
	const canEdit = verified && role !== "viewer";
	const canAddDetails = verified && (role !== "viewer" || myMemberId === to.id);
	const canResolve =
		role === "owner" ||
		myMemberId === to.id ||
		(role === "editor" && !to.claimed);
	const canCancel = Boolean(transfer.pendingRequest?.createdByMe) || isFromSide;
	const payAmount = Math.min(transfer.amount, MAX_TRANSFER_AMOUNT);
	const isPartial = transfer.amount > MAX_TRANSFER_AMOUNT;

	const defaultChannel: PaymentChannel | null =
		transfer.payTo[0]?.kind === "bank" ||
		transfer.payTo[0]?.kind === "momo" ||
		transfer.payTo[0]?.kind === "zalopay"
			? transfer.payTo[0].kind
			: null;
	const [channel, setChannel] = useState<PaymentChannel | null>(defaultChannel);
	const [note, setNote] = useState("");
	const [attachments, setAttachments] = useState<AttachmentDto[]>([]);
	const [uploadingProof, setUploadingProof] = useState(false);

	return (
		<main className="mx-auto flex min-h-dvh max-w-[430px] flex-col gap-5 px-5 py-6 pb-28">
			<ScreenHeader
				title={t(vi.pay.title, { to: to.name })}
				backHref={`/g/${groupId}/balances`}
				backLabel={vi.common.back}
			/>
			<div className="flex items-center justify-around rounded-[36px] bg-surface p-4">
				{[
					{ member: from, household: transfer.fromHousehold },
					{ member: to, household: transfer.toHousehold },
				].map(({ member, household }, index) => (
					<div key={member.id} className="flex items-center gap-3">
						<div className="grid justify-items-center gap-1.5 text-center">
							<MemberShape {...member} size={56} />
							<span className="text-sm font-extrabold">
								{member.id === myMemberId ? vi.common.you : member.name}
							</span>
							{household && (
								<span className="rounded-pill bg-sunken px-2 py-0.5 text-[11px] font-bold text-muted">
									{t(vi.households.representativeBadge, {
										name: household.name,
									})}
								</span>
							)}
						</div>
						{index === 0 && <Icon name="arrow-right" size={20} />}
					</div>
				))}
			</div>
			<div className="grid justify-items-center gap-2 text-center">
				<p className="text-[40px] font-black tracking-tight">
					{formatMoney(payAmount)}
				</p>
				<CopyRow
					label={vi.pay.copyAmount}
					value={formatMoney(payAmount)}
					copyValue={String(payAmount)}
					buttonLabel={vi.pay.copyAmount}
					compact
				/>
				{isPartial && (
					<p className="text-xs font-semibold text-muted">
						{t(vi.pay.partialNote, {
							amount: formatMoney(payAmount),
							total: formatMoney(transfer.amount),
						})}
					</p>
				)}
			</div>
			<PayMethodsCard
				groupId={groupId}
				transfer={transfer}
				toName={to.name}
				canAddDetails={canAddDetails}
			/>
			{!transfer.pendingRequest && mayCreate && verified && (
				<TransferProofFields
					groupId={groupId}
					channel={channel}
					onChannelChange={setChannel}
					note={note}
					onNoteChange={setNote}
					attachments={attachments}
					onAddAttachment={(attachment) =>
						setAttachments((current) =>
							current.length >= 1 ? current : [attachment],
						)
					}
					onRemoveAttachment={(id) =>
						setAttachments((current) =>
							current.filter((item) => item.id !== id),
						)
					}
					maxAttachments={1}
					uploadPurpose="transfer_proof"
					onUploadingChange={setUploadingProof}
				/>
			)}
			<PayFooter
				groupId={groupId}
				from={from}
				to={to}
				transfer={transfer}
				payAmount={payAmount}
				mayCreate={mayCreate}
				canEdit={canEdit}
				canResolve={canResolve}
				canCancel={canCancel}
				verified={verified}
				channel={channel}
				note={note}
				proofAttachmentId={attachments[0]?.id ?? null}
				uploadingProof={uploadingProof}
			/>
		</main>
	);
}
