"use client";
import { useRouter } from "next/navigation";
import { type ChangeEvent, useRef, useState } from "react";
import { vi } from "../../messages/vi";
import { Button } from "../ui/Button";
import { PhotoViewer } from "../ui/PhotoViewer";
import { ScreenHeader } from "../ui/ScreenHeader";
import { useReceiptRetake } from "./use-receipt-retake";

export function ReceiptPhoto({
	imageUrl,
	size,
}: {
	imageUrl: string;
	size: "small" | "large";
}) {
	const [viewerOpen, setViewerOpen] = useState(false);
	const box = size === "large" ? "h-24 w-24" : "h-20 w-20 shrink-0";
	const image = size === "large" ? "h-24 w-24" : "h-20 w-20";
	return (
		<>
			<button
				type="button"
				onClick={() => setViewerOpen(true)}
				aria-label={vi.attachments.viewPhoto}
				className={`${box} overflow-hidden rounded-[20px] bg-sunken`}
			>
				<img
					src={imageUrl}
					alt={vi.attachments.label}
					className={`${image} object-cover`}
				/>
			</button>
			{viewerOpen && (
				<PhotoViewer
					src={imageUrl}
					alt={vi.attachments.label}
					onClose={() => setViewerOpen(false)}
				/>
			)}
		</>
	);
}

function ClosableHeader({ groupId }: { groupId: string }) {
	return (
		<ScreenHeader
			title={vi.receipts.title}
			backHref={`/g/${groupId}`}
			backLabel={vi.common.cancel}
			backIcon="close"
		/>
	);
}

export function ReceiptLoadingView({ groupId }: { groupId: string }) {
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

export function ReceiptLoadErrorView({
	groupId,
}: {
	groupId: string;
	notFound?: boolean;
}) {
	return (
		<div className="grid gap-4">
			<ScreenHeader
				title={vi.receipts.title}
				backHref={`/g/${groupId}`}
				backLabel={vi.common.back}
			/>
			<p role="alert" className="text-sm font-bold text-ink">
				{vi.common.loadError}
			</p>
		</div>
	);
}

export function ReceiptPendingView({
	groupId,
	imageUrl,
}: {
	groupId: string;
	imageUrl: string;
}) {
	return (
		<div className="grid gap-4">
			<ClosableHeader groupId={groupId} />
			<ReceiptPhoto imageUrl={imageUrl} size="large" />
			<p role="status" className="text-base font-extrabold text-ink">
				{vi.receipts.reading}
			</p>
		</div>
	);
}

export function ReceiptFailedView({
	groupId,
	imageUrl,
	attachmentId,
	notAReceipt,
}: {
	groupId: string;
	imageUrl: string;
	attachmentId: string;
	notAReceipt: boolean;
}) {
	const router = useRouter();
	const retake = useReceiptRetake(groupId);
	const inputRef = useRef<HTMLInputElement>(null);
	const handleChange = (event: ChangeEvent<HTMLInputElement>) => {
		const file = event.target.files?.[0];
		event.target.value = "";
		if (file) void retake.scanNewFile(file);
	};
	return (
		<div className="grid gap-4">
			<ClosableHeader groupId={groupId} />
			<input
				ref={inputRef}
				type="file"
				accept="image/*"
				tabIndex={-1}
				aria-hidden="true"
				onChange={handleChange}
				className="sr-only"
			/>
			<ReceiptPhoto imageUrl={imageUrl} size="large" />
			<div className="grid gap-3 rounded-[26px] bg-surface p-4">
				<p role="alert" className="text-base font-extrabold text-ink">
					{notAReceipt ? vi.receipts.notAReceipt : vi.receipts.failed}
				</p>
				{retake.error && (
					<p role="alert" className="text-xs font-bold text-ink">
						{retake.error}
					</p>
				)}
				<div className="flex flex-wrap gap-2">
					<Button
						type="button"
						variant="primary"
						disabled={retake.busy}
						onClick={() =>
							notAReceipt
								? inputRef.current?.click()
								: void retake.rescanAttachment(attachmentId)
						}
					>
						{notAReceipt ? vi.receipts.retake : vi.receipts.retry}
					</Button>
					<Button
						type="button"
						variant="surface"
						disabled={retake.busy}
						onClick={() =>
							router.push(
								`/g/${groupId}/tx/new?form&attachmentId=${attachmentId}`,
							)
						}
					>
						{vi.receipts.manualEntry}
					</Button>
				</div>
			</div>
		</div>
	);
}
