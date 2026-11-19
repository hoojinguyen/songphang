"use client";
import type { MemberDto } from "@songphang/contract";
import { useRouter } from "next/navigation";
import { useRef, useState } from "react";
import { attachmentContentUrl } from "../../lib/attachments";
import { useGroup } from "../../lib/groups";
import { formatMoney } from "../../lib/money";
import { usePreviewItems, useReceiptScan } from "../../lib/receipt-scans";
import { useCreateTransaction } from "../../lib/transactions";
import { useSessionGuard } from "../../lib/use-session-guard";
import { t, vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { useSnackbar } from "../ui/Snackbar";
import { ItemsAssignmentPanel, toItemsPayload } from "./ItemsAssignmentPanel";
import { MismatchNotice } from "./MismatchNotice";
import { ReceiptDetailsFields } from "./ReceiptDetailsFields";
import { ReceiptPayerPicker } from "./ReceiptPayerPicker";
import {
	ReceiptFailedView,
	ReceiptLoadErrorView,
	ReceiptLoadingView,
	ReceiptPendingView,
} from "./ReceiptScanStates";
import { buildReceiptRequest, receiptMismatch } from "./receipt-review-rules";
import { useReceiptEditor } from "./use-receipt-editor";

export function ReceiptReview({
	groupId,
	scanId,
	members,
	myMemberId,
}: {
	groupId: string;
	scanId: string;
	members: MemberDto[];
	myMemberId: string | null;
}) {
	const router = useRouter();
	const group = useGroup(groupId);
	const snackbar = useSnackbar();
	const scanQuery = useReceiptScan(groupId, scanId);
	useSessionGuard(scanQuery.error);
	const createMutation = useCreateTransaction(groupId);
	useSessionGuard(createMutation.error);
	const [idempotencyKey] = useState(() => crypto.randomUUID());
	const submittingRef = useRef(false);

	const activePeople = members.filter(
		(member) => member.kind === "person" && member.active,
	);
	const activeFund = members.find(
		(member) => member.kind === "fund" && member.active,
	);
	const payerOptions = activeFund
		? [...activePeople, activeFund]
		: activePeople;

	const scan = scanQuery.data?.scan;
	const editor = useReceiptEditor({
		scan,
		myMemberId,
		payerOptions,
		activePeople,
	});
	const itemsPayload = editor.ready
		? toItemsPayload(editor.items, editor.extras)
		: null;
	const printedTotal = scan?.reading?.total ?? null;
	const preview = usePreviewItems(
		groupId,
		itemsPayload && printedTotal !== null
			? { ...itemsPayload, targetTotal: printedTotal }
			: itemsPayload,
	);
	useSessionGuard(preview.error);

	if (scanQuery.isPending) return <ReceiptLoadingView groupId={groupId} />;
	if (scanQuery.isError || !scan) {
		return (
			<ReceiptLoadErrorView
				groupId={groupId}
				notFound={scanQuery.error?.status === 404}
			/>
		);
	}

	const imageUrl = attachmentContentUrl(groupId, scan.attachmentId);
	const isPending =
		!scanQuery.timedOut &&
		(scan.status === "queued" || scan.status === "processing");
	if (isPending) {
		return <ReceiptPendingView groupId={groupId} imageUrl={imageUrl} />;
	}
	if (
		scan.status === "failed" ||
		(scanQuery.timedOut && scan.status !== "done")
	) {
		return (
			<ReceiptFailedView
				groupId={groupId}
				imageUrl={imageUrl}
				attachmentId={scan.attachmentId}
				notAReceipt={scan.errorCode === "NOT_A_RECEIPT"}
			/>
		);
	}

	const computedAmount = preview.current
		? preview.data?.computedAmount
		: undefined;
	const mismatch = receiptMismatch(scan, computedAmount);
	const showMismatch = !editor.mismatchDismissed && mismatch !== null;
	const request = buildReceiptRequest({
		editor,
		itemsPayload,
		preview: preview.current ? preview.data : undefined,
		attachmentId: scan.attachmentId,
	});
	const canSave =
		!submittingRef.current &&
		!createMutation.isPending &&
		!showMismatch &&
		request !== null;

	const save = () => {
		if (!canSave || request === null) return;
		submittingRef.current = true;
		createMutation.mutate(
			{ request, key: idempotencyKey },
			{
				onSuccess: (data) => {
					if (data.transaction.approval.status === "pending") {
						snackbar({
							text: t(vi.approval.savedPending, {
								owner: group.data?.ownerName ?? "",
							}),
						});
					}
					router.replace(`/g/${groupId}`);
				},
				onSettled: () => {
					submittingRef.current = false;
				},
			},
		);
	};

	const applyPrintedTotal = () => {
		const adjustment = preview.current
			? preview.data?.targetAdjustment
			: undefined;
		if (editor.extrasFull || adjustment === undefined) return;
		if (adjustment !== null) editor.addMismatchExtra(adjustment);
		editor.dismissMismatch();
	};

	return (
		<div className="flex flex-1 flex-col gap-3 pb-6">
			<ReceiptDetailsFields
				groupId={groupId}
				imageUrl={imageUrl}
				description={editor.description}
				onDescriptionChange={editor.setDescription}
				occurredOn={editor.occurredOn}
				onOccurredOnChange={editor.setOccurredOn}
			/>

			{showMismatch && (
				<MismatchNotice
					computed={computedAmount ?? mismatch.scanComputed}
					printedTotal={mismatch.printedTotal}
					extrasFull={editor.extrasFull}
					printedPending={computedAmount === undefined}
					onUseComputed={editor.dismissMismatch}
					onUsePrintedTotal={applyPrintedTotal}
				/>
			)}

			<ItemsAssignmentPanel
				items={editor.items}
				extras={editor.extras}
				selectedItemId={editor.selectedItemId}
				activePeople={activePeople}
				previewData={preview.data}
				previewCurrent={preview.current}
				previewError={preview.isError}
				{...editor.panelHandlers}
			/>

			<div className="rounded-[26px] bg-surface p-4 text-center">
				<p className="text-[32px] font-black tracking-tight text-ink">
					{computedAmount !== undefined
						? formatMoney(computedAmount)
						: vi.common.pendingValue}
				</p>
			</div>

			<ReceiptPayerPicker
				payerOptions={payerOptions}
				payerId={editor.payerId}
				onChange={editor.setPayerId}
			/>

			{createMutation.isError && (
				<p role="alert" className="text-xs font-bold text-ink">
					{createMutation.error.status === 403
						? vi.common.forbidden
						: vi.common.saveError}
				</p>
			)}

			<Button
				type="button"
				variant="accent"
				size="lg"
				disabled={!canSave}
				onClick={save}
				className="mt-auto w-full"
			>
				{vi.receipts.save}
			</Button>
		</div>
	);
}
