"use client";
import {
	CreateTransactionRequest,
	type MemberDto,
	type ReceiptScanDto,
} from "@songphang/contract";
import { useRouter } from "next/navigation";
import { type ChangeEvent, useEffect, useRef, useState } from "react";
import { ApiError } from "../../lib/api";
import { attachmentContentUrl, uploadAttachment } from "../../lib/attachments";
import { formatMoney } from "../../lib/money";
import { prepareImage } from "../../lib/prepare-image";
import {
	createReceiptScan,
	usePreviewItems,
	useReceiptScan,
} from "../../lib/receipt-scans";
import { useCreateTransaction } from "../../lib/transactions";
import { useSessionGuard } from "../../lib/use-session-guard";
import { vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { MemberShape } from "../ui/MemberShape";
import { PhotoViewer } from "../ui/PhotoViewer";
import { ScreenHeader } from "../ui/ScreenHeader";
import type { EditableReceiptExtra } from "./ExtrasFields";
import type { EditableReceiptItem } from "./ItemRow";
import { ItemsAssignmentPanel, toItemsPayload } from "./ItemsAssignmentPanel";
import { MismatchNotice } from "./MismatchNotice";

function todayVietnamDate(): string {
	return new Date(Date.now() + 7 * 3600_000).toISOString().slice(0, 10);
}

function buildInitialEditorState(
	scan: ReceiptScanDto,
	myMemberId: string | null,
	payerOptions: MemberDto[],
) {
	const reading = scan.reading;
	const merchant = reading?.merchant?.trim() || vi.receipts.title;
	const hasItems = (reading?.items.length ?? 0) > 0;
	const items: EditableReceiptItem[] = hasItems
		? (reading?.items.map((item) => ({
				id: crypto.randomUUID(),
				name: item.name,
				amountText: String(item.amount),
				memberIds: [],
			})) ?? [])
		: [
				{
					id: crypto.randomUUID(),
					name: merchant,
					amountText:
						reading?.total !== null && reading?.total !== undefined
							? String(reading.total)
							: "0",
					memberIds: [],
				},
			];
	const extras: EditableReceiptExtra[] = hasItems
		? (reading?.extras.map((extra) => ({
				id: crypto.randomUUID(),
				kind: extra.kind,
				label: extra.label,
				amountText: String(extra.amount),
			})) ?? [])
		: [];
	const defaultPayer =
		payerOptions.find((m) => m.id === myMemberId)?.id ??
		payerOptions[0]?.id ??
		null;
	return {
		description: merchant,
		occurredOn: reading?.occurredOn ?? todayVietnamDate(),
		items,
		extras,
		selectedItemId: items[0]?.id ?? "",
		payerId: defaultPayer,
	};
}

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
	const scanQuery = useReceiptScan(groupId, scanId);
	useSessionGuard(scanQuery.error);
	const createMutation = useCreateTransaction(groupId);
	useSessionGuard(createMutation.error);

	const activePeople = members.filter(
		(member) => member.kind === "person" && member.active,
	);
	const activeFund = members.find(
		(member) => member.kind === "fund" && member.active,
	);
	const payerOptions = activeFund
		? [...activePeople, activeFund]
		: activePeople;

	const retakeInputRef = useRef<HTMLInputElement>(null);
	const [retakeBusy, setRetakeBusy] = useState(false);
	const [retakeError, setRetakeError] = useState<string | null>(null);
	const [viewerOpen, setViewerOpen] = useState(false);
	const [idempotencyKey] = useState(() => crypto.randomUUID());
	const submittingRef = useRef(false);

	const [initializedScanId, setInitializedScanId] = useState<string | null>(
		null,
	);
	const [description, setDescription] = useState<string>(vi.receipts.title);
	const [occurredOn, setOccurredOn] = useState<string>(todayVietnamDate);
	const [items, setItems] = useState<EditableReceiptItem[]>([]);
	const [extras, setExtras] = useState<EditableReceiptExtra[]>([]);
	const [selectedItemId, setSelectedItemId] = useState("");
	const [payerId, setPayerId] = useState<string | null>(null);
	const [mismatchDismissed, setMismatchDismissed] = useState(false);

	const scan = scanQuery.data?.scan;
	useEffect(() => {
		if (scan?.status !== "done" || initializedScanId === scan.id) {
			return;
		}
		const init = buildInitialEditorState(scan, myMemberId, payerOptions);
		setDescription(init.description);
		setOccurredOn(init.occurredOn);
		setItems(init.items);
		setExtras(init.extras);
		setSelectedItemId(init.selectedItemId);
		setPayerId(init.payerId);
		setMismatchDismissed(false);
		setInitializedScanId(scan.id);
	}, [scan, initializedScanId, myMemberId, payerOptions]);

	const itemsPayload =
		scan?.status === "done" && initializedScanId === scan.id
			? toItemsPayload(items, extras)
			: null;
	const preview = usePreviewItems(groupId, itemsPayload);
	useSessionGuard(preview.error);

	const handleNewUploadFile = async (file: File) => {
		if (retakeBusy) return;
		setRetakeBusy(true);
		setRetakeError(null);
		try {
			let prepared: Blob;
			try {
				prepared = await prepareImage(file);
			} catch {
				setRetakeError(vi.receipts.notAnImage);
				return;
			}
			const attachment = await uploadAttachment(
				groupId,
				prepared,
				file.name || "hoa-don.jpg",
			);
			const res = await createReceiptScan(
				groupId,
				attachment.id,
				crypto.randomUUID(),
			);
			router.replace(`/g/${groupId}/tx/new?scan=${res.scan.id}`);
		} catch (error) {
			if (error instanceof ApiError && error.code === "AI_QUOTA_EXCEEDED") {
				setRetakeError(vi.receipts.dailyLimit);
			} else if (error instanceof Error && error.message === "not an image") {
				setRetakeError(vi.receipts.notAnImage);
			} else if (error instanceof Error && error.message === "too large") {
				setRetakeError(vi.receipts.fileTooLarge);
			} else {
				setRetakeError(vi.common.saveError);
			}
		} finally {
			setRetakeBusy(false);
		}
	};

	const handleRetakeChange = (event: ChangeEvent<HTMLInputElement>) => {
		const file = event.target.files?.[0];
		event.target.value = "";
		if (file) void handleNewUploadFile(file);
	};

	const handleRetryCurrentAttachment = async () => {
		if (!scan || retakeBusy) return;
		setRetakeBusy(true);
		setRetakeError(null);
		try {
			const imgRes = await fetch(
				attachmentContentUrl(groupId, scan.attachmentId),
				{ credentials: "include", cache: "no-store" },
			);
			if (!imgRes.ok) throw new Error("fetch failed");
			const blob = await imgRes.blob();
			const attachment = await uploadAttachment(groupId, blob, "hoa-don.jpg");
			const created = await createReceiptScan(
				groupId,
				attachment.id,
				crypto.randomUUID(),
			);
			router.replace(`/g/${groupId}/tx/new?scan=${created.scan.id}`);
		} catch (error) {
			if (error instanceof ApiError && error.code === "AI_QUOTA_EXCEEDED") {
				setRetakeError(vi.receipts.dailyLimit);
			} else {
				setRetakeError(vi.common.saveError);
			}
		} finally {
			setRetakeBusy(false);
		}
	};

	if (scanQuery.isPending) {
		return (
			<div aria-busy="true" className="grid gap-4">
				<ScreenHeader
					title={vi.receipts.title}
					backHref={`/g/${groupId}`}
					backLabel={vi.common.back}
				/>
				<div className="h-24 rounded-card bg-sunken" />
				<div className="h-48 rounded-card bg-sunken" />
			</div>
		);
	}

	if (scanQuery.isError || !scan) {
		return (
			<div className="grid gap-4">
				<ScreenHeader
					title={vi.receipts.title}
					backHref={`/g/${groupId}`}
					backLabel={vi.common.back}
				/>
				<p role="alert" className="text-sm font-bold text-ink">
					{scanQuery.error?.status === 404
						? vi.common.groupNotFound
						: vi.common.loadError}
				</p>
			</div>
		);
	}

	const imageUrl = attachmentContentUrl(groupId, scan.attachmentId);
	const isPending =
		!scanQuery.timedOut &&
		(scan.status === "queued" || scan.status === "processing");
	const isFailed =
		scan.status === "failed" || (scanQuery.timedOut && scan.status !== "done");

	if (isPending) {
		return (
			<div className="grid gap-4">
				<ScreenHeader
					title={vi.receipts.title}
					backHref={`/g/${groupId}`}
					backLabel={vi.common.cancel}
					backIcon="close"
				/>
				<button
					type="button"
					onClick={() => setViewerOpen(true)}
					aria-label={vi.attachments.viewPhoto}
					className="h-24 w-24 overflow-hidden rounded-[20px] bg-sunken"
				>
					<img
						src={imageUrl}
						alt={vi.attachments.label}
						className="h-24 w-24 object-cover"
					/>
				</button>
				<p role="status" className="text-base font-extrabold text-ink">
					{vi.receipts.reading}
				</p>
				{viewerOpen && (
					<PhotoViewer
						src={imageUrl}
						alt={vi.attachments.label}
						onClose={() => setViewerOpen(false)}
					/>
				)}
			</div>
		);
	}

	if (isFailed) {
		const notAReceipt = scan.errorCode === "NOT_A_RECEIPT";
		return (
			<div className="grid gap-4">
				<ScreenHeader
					title={vi.receipts.title}
					backHref={`/g/${groupId}`}
					backLabel={vi.common.cancel}
					backIcon="close"
				/>
				<input
					ref={retakeInputRef}
					type="file"
					accept="image/*"
					tabIndex={-1}
					aria-hidden="true"
					onChange={handleRetakeChange}
					className="sr-only"
				/>
				<button
					type="button"
					onClick={() => setViewerOpen(true)}
					aria-label={vi.attachments.viewPhoto}
					className="h-24 w-24 overflow-hidden rounded-[20px] bg-sunken"
				>
					<img
						src={imageUrl}
						alt={vi.attachments.label}
						className="h-24 w-24 object-cover"
					/>
				</button>
				<div className="grid gap-3 rounded-[26px] bg-surface p-4">
					<p role="alert" className="text-base font-extrabold text-ink">
						{notAReceipt ? vi.receipts.notAReceipt : vi.receipts.failed}
					</p>
					{retakeError && (
						<p role="alert" className="text-xs font-bold text-ink">
							{retakeError}
						</p>
					)}
					<div className="flex flex-wrap gap-2">
						{notAReceipt ? (
							<Button
								type="button"
								variant="primary"
								disabled={retakeBusy}
								onClick={() => retakeInputRef.current?.click()}
							>
								{vi.receipts.retake}
							</Button>
						) : (
							<Button
								type="button"
								variant="primary"
								disabled={retakeBusy}
								onClick={() => void handleRetryCurrentAttachment()}
							>
								{vi.receipts.retry}
							</Button>
						)}
						<Button
							type="button"
							variant="surface"
							onClick={() =>
								router.push(
									`/g/${groupId}/tx/new?form&attachmentId=${scan.attachmentId}`,
								)
							}
						>
							{vi.receipts.manualEntry}
						</Button>
					</div>
				</div>
				{viewerOpen && (
					<PhotoViewer
						src={imageUrl}
						alt={vi.attachments.label}
						onClose={() => setViewerOpen(false)}
					/>
				)}
			</div>
		);
	}

	const computedAmount = preview.current
		? preview.data?.computedAmount
		: undefined;
	const hasMismatch =
		scan.flags.includes("TOTAL_MISMATCH") &&
		!scan.flags.includes("NO_ITEMS") &&
		scan.computed !== null &&
		scan.reading?.total !== null &&
		scan.reading?.total !== undefined &&
		(computedAmount === undefined || computedAmount !== scan.reading.total);
	const showMismatch = !mismatchDismissed && hasMismatch;

	const hasPreviewShares =
		preview.current &&
		preview.data &&
		preview.data.issues.length === 0 &&
		(preview.data.shares?.length ?? 0) > 0;
	const canSave =
		!submittingRef.current &&
		!createMutation.isPending &&
		!showMismatch &&
		itemsPayload !== null &&
		hasPreviewShares &&
		computedAmount !== undefined &&
		computedAmount > 0 &&
		payerId !== null &&
		description.trim().length > 0 &&
		/^\d{4}-\d{2}-\d{2}$/.test(occurredOn);

	const save = () => {
		if (
			!canSave ||
			!itemsPayload ||
			computedAmount === undefined ||
			payerId === null
		) {
			return;
		}
		const requestCheck = CreateTransactionRequest.safeParse({
			type: "expense",
			description: description.trim(),
			amount: computedAmount,
			occurredAt: new Date(`${occurredOn}T12:00:00+07:00`).toISOString(),
			category: null,
			categoryId: null,
			payers: [{ memberId: payerId, amount: computedAmount }],
			split: {
				method: "items",
				items: itemsPayload.items,
				extras: itemsPayload.extras,
			},
			attachmentIds: [scan.attachmentId],
		});
		if (!requestCheck.success) return;
		submittingRef.current = true;
		createMutation.mutate(
			{ request: requestCheck.data, key: idempotencyKey },
			{
				onSuccess: () => {
					router.replace(`/g/${groupId}`);
				},
				onSettled: () => {
					submittingRef.current = false;
				},
			},
		);
	};

	return (
		<div className="flex flex-1 flex-col gap-3 pb-6">
			<div>
				<ScreenHeader
					title={vi.receipts.title}
					backHref={`/g/${groupId}`}
					backLabel={vi.common.cancel}
					backIcon="close"
				/>
				<p className="mt-1 text-xs font-semibold text-muted">
					{vi.receipts.aiNote}
				</p>
			</div>

			<div className="flex items-start gap-3">
				<button
					type="button"
					onClick={() => setViewerOpen(true)}
					aria-label={vi.attachments.viewPhoto}
					className="h-20 w-20 shrink-0 overflow-hidden rounded-[20px] bg-sunken"
				>
					<img
						src={imageUrl}
						alt={vi.attachments.label}
						className="h-20 w-20 object-cover"
					/>
				</button>
				<div className="grid min-w-0 flex-1 gap-2">
					<input
						aria-label={vi.receipts.descriptionLabel}
						maxLength={200}
						value={description}
						onChange={(event) => setDescription(event.target.value)}
						className="h-11 rounded-[18px] bg-surface px-3 text-base font-extrabold text-ink"
					/>
					<input
						aria-label={vi.receipts.dateLabel}
						type="date"
						value={occurredOn}
						onChange={(event) => setOccurredOn(event.target.value)}
						className="h-11 rounded-[18px] bg-surface px-3 text-base text-ink"
					/>
				</div>
			</div>

			{showMismatch &&
				scan.computed !== null &&
				scan.reading?.total !== null &&
				scan.reading?.total !== undefined && (
					<MismatchNotice
						computed={computedAmount ?? scan.computed}
						printedTotal={scan.reading.total}
						extrasFull={extras.length >= 6}
						printedPending={computedAmount === undefined}
						onUseComputed={() => {
							setMismatchDismissed(true);
						}}
						onUsePrintedTotal={() => {
							if (
								extras.length >= 6 ||
								computedAmount === undefined ||
								scan.reading?.total === null ||
								scan.reading?.total === undefined
							) {
								return;
							}
							const diff = scan.reading.total - computedAmount;
							if (diff !== 0) {
								setExtras((current) => [
									...current,
									{
										id: crypto.randomUUID(),
										kind: diff > 0 ? "other" : "discount",
										label: vi.receipts.mismatchExtraLabel,
										amountText: String(Math.abs(diff)),
									},
								]);
							}
							setMismatchDismissed(true);
						}}
					/>
				)}

			<ItemsAssignmentPanel
				items={items}
				extras={extras}
				selectedItemId={selectedItemId}
				activePeople={activePeople}
				previewData={preview.data}
				previewCurrent={preview.current}
				previewError={preview.isError}
				onSelectItem={setSelectedItemId}
				onChangeItem={(id, patch) => {
					setItems((current) =>
						current.map((item) =>
							item.id === id ? { ...item, ...patch } : item,
						),
					);
				}}
				onRemoveItem={(id) => {
					setItems((current) => {
						if (current.length <= 1) return current;
						const next = current.filter((item) => item.id !== id);
						if (selectedItemId === id) {
							setSelectedItemId(next[0]?.id ?? "");
						}
						return next;
					});
				}}
				onAddItem={() => {
					if (items.length >= 60) return;
					const nextId = crypto.randomUUID();
					setItems((current) => [
						...current,
						{ id: nextId, name: "", amountText: "0", memberIds: [] },
					]);
					setSelectedItemId(nextId);
				}}
				onToggleMemberOnSelected={(memberId) => {
					const targetId = selectedItemId || items[0]?.id;
					if (!targetId) return;
					setItems((current) =>
						current.map((item) => {
							if (item.id !== targetId) return item;
							const exists = item.memberIds.includes(memberId);
							return {
								...item,
								memberIds: exists
									? item.memberIds.filter((id) => id !== memberId)
									: [...item.memberIds, memberId],
							};
						}),
					);
				}}
				onSplitRemainingEqual={() => {
					const allIds = activePeople.map((m) => m.id);
					if (allIds.length === 0) return;
					setItems((current) =>
						current.map((item) =>
							item.memberIds.length === 0
								? { ...item, memberIds: allIds }
								: item,
						),
					);
				}}
				onAddExtra={() => {
					if (extras.length >= 6) return;
					setExtras((current) => [
						...current,
						{
							id: crypto.randomUUID(),
							kind: "other",
							label: "",
							amountText: "0",
						},
					]);
				}}
				onChangeExtra={(id, patch) => {
					setExtras((current) =>
						current.map((extra) =>
							extra.id === id ? { ...extra, ...patch } : extra,
						),
					);
				}}
				onRemoveExtra={(id) => {
					setExtras((current) => current.filter((extra) => extra.id !== id));
				}}
			/>

			<div className="rounded-[26px] bg-surface p-4 text-center">
				<p className="text-[32px] font-black tracking-tight text-ink">
					{computedAmount !== undefined
						? formatMoney(computedAmount)
						: vi.common.pendingValue}
				</p>
			</div>

			<section className="grid gap-2 rounded-[26px] bg-surface p-3">
				<h2 className="text-xs font-extrabold text-muted">
					{vi.receipts.paidBy}
				</h2>
				<div className="flex flex-wrap gap-2">
					{payerOptions.map((member) => {
						const activePayer = payerId === member.id;
						return (
							<button
								key={member.id}
								type="button"
								aria-pressed={activePayer}
								onClick={() => setPayerId(member.id)}
								className={`flex min-h-11 items-center gap-2 rounded-pill px-3 text-xs font-extrabold ${
									activePayer ? "bg-ink text-surface" : "bg-sunken text-ink"
								}`}
							>
								<MemberShape {...member} size={22} />
								{member.name}
							</button>
						);
					})}
				</div>
			</section>

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

			{viewerOpen && (
				<PhotoViewer
					src={imageUrl}
					alt={vi.attachments.label}
					onClose={() => setViewerOpen(false)}
				/>
			)}
		</div>
	);
}
