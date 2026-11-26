"use client";
import type {
	AttachmentDto,
	AttachmentUploadPurpose,
	PaymentChannel,
} from "@songphang/contract";
import { useRef, useState } from "react";
import { ApiError } from "../../lib/api";
import { attachmentContentUrl, uploadAttachment } from "../../lib/attachments";
import { prepareImage } from "../../lib/prepare-image";
import { vi } from "../../messages/vi";
import { Icon } from "../ui/Icon";
import { PhotoViewer } from "../ui/PhotoViewer";

export const PAYMENT_CHANNEL_OPTIONS: Array<{
	value: PaymentChannel;
	label: string;
}> = [
	{ value: "bank", label: vi.settlementProof.channelBank },
	{ value: "momo", label: vi.settlementProof.channelMomo },
	{ value: "zalopay", label: vi.settlementProof.channelZalopay },
	{ value: "cash", label: vi.settlementProof.channelCash },
];

export function paymentChannelLabel(channel: PaymentChannel): string {
	return (
		PAYMENT_CHANNEL_OPTIONS.find((option) => option.value === channel)?.label ??
		channel
	);
}

function mapUploadError(error: unknown): string {
	if (error instanceof ApiError) {
		if (error.status === 413 || error.details?.reason === "too_large") {
			return vi.receipts.fileTooLarge;
		}
		if (error.details?.reason === "not_an_image") {
			return vi.receipts.notAnImage;
		}
		if (error.code === "STORAGE_QUOTA_EXCEEDED") {
			return vi.attachments.quotaExceeded;
		}
		if (error.status === 429) {
			return vi.attachments.rateLimited;
		}
		if (error.status === 403) {
			return vi.common.forbidden;
		}
		return vi.common.saveError;
	}
	return vi.receipts.notAnImage;
}

export function TransferProofFields({
	groupId,
	channel,
	onChannelChange,
	note,
	onNoteChange,
	attachments,
	onAddAttachment,
	onRemoveAttachment,
	maxAttachments = 1,
	uploadPurpose = "transfer_proof",
	onUploadingChange,
}: {
	groupId: string;
	channel: PaymentChannel | null;
	onChannelChange: (channel: PaymentChannel | null) => void;
	note: string;
	onNoteChange: (note: string) => void;
	attachments: AttachmentDto[];
	onAddAttachment: (attachment: AttachmentDto) => void;
	onRemoveAttachment: (id: string) => void;
	maxAttachments?: number;
	uploadPurpose?: AttachmentUploadPurpose;
	onUploadingChange?: (uploading: boolean) => void;
}) {
	const inputRef = useRef<HTMLInputElement>(null);
	const [uploading, setUploading] = useState(false);
	const [errorText, setErrorText] = useState<string | null>(null);
	const [viewingId, setViewingId] = useState<string | null>(null);

	const handleFile = async (file: File | undefined) => {
		if (!file) return;
		if (attachments.length >= maxAttachments) {
			setErrorText(vi.attachments.maxLimit);
			return;
		}
		setErrorText(null);
		setUploading(true);
		onUploadingChange?.(true);
		try {
			const prepared = await prepareImage(file);
			const uploaded = await uploadAttachment(
				groupId,
				prepared,
				"chung-tu.jpg",
				uploadPurpose,
			);
			onAddAttachment(uploaded);
		} catch (error) {
			setErrorText(mapUploadError(error));
		} finally {
			setUploading(false);
			onUploadingChange?.(false);
			if (inputRef.current) inputRef.current.value = "";
		}
	};

	return (
		<section className="grid gap-3.5 rounded-[28px] bg-surface p-4">
			<div className="grid gap-2">
				<span className="text-xs font-extrabold text-muted">
					{vi.settlementProof.channelLabel}
				</span>
				<div className="flex flex-wrap gap-2">
					{PAYMENT_CHANNEL_OPTIONS.map((option) => {
						const active = channel === option.value;
						return (
							<button
								key={option.value}
								type="button"
								aria-pressed={active}
								onClick={() => onChannelChange(active ? null : option.value)}
								className={`min-h-11 rounded-pill px-3.5 text-xs font-bold transition-colors ${
									active
										? "bg-ink text-on-ink"
										: "bg-sunken text-ink hover:bg-border-subtle"
								}`}
							>
								{option.label}
							</button>
						);
					})}
				</div>
			</div>

			<div className="grid gap-2">
				<span className="text-xs font-extrabold text-muted">
					{vi.settlementProof.photoLabel}
				</span>
				<input
					ref={inputRef}
					type="file"
					accept="image/jpeg,image/png,image/webp"
					className="hidden"
					onChange={(event) => {
						void handleFile(event.target.files?.[0]);
					}}
				/>
				<div className="flex flex-wrap items-center gap-3">
					{attachments.map((attachment) => (
						<div key={attachment.id} className="relative">
							<button
								type="button"
								aria-label={vi.settlementProof.viewProof}
								onClick={() => setViewingId(attachment.id)}
								className="block h-14 w-14 overflow-hidden rounded-[14px] bg-sunken"
							>
								<img
									src={attachmentContentUrl(groupId, attachment.id)}
									alt={vi.settlementProof.viewProof}
									className="h-14 w-14 rounded-[14px] object-cover"
								/>
							</button>
							<button
								type="button"
								aria-label={vi.settlementProof.removePhoto}
								onClick={() => {
									setErrorText(null);
									onRemoveAttachment(attachment.id);
								}}
								className="absolute -right-2 -top-2 flex h-11 w-11 items-center justify-center rounded-full"
							>
								<span className="flex h-6 w-6 items-center justify-center rounded-full bg-ink text-on-ink">
									<Icon name="close" size={14} />
								</span>
							</button>
						</div>
					))}
					{attachments.length < maxAttachments && (
						<button
							type="button"
							disabled={uploading}
							onClick={() => inputRef.current?.click()}
							className="inline-flex min-h-11 items-center gap-2 rounded-pill bg-sunken px-4 text-xs font-bold text-ink disabled:opacity-50"
						>
							<Icon name="image" size={16} />
							<span>{vi.settlementProof.attachPhoto}</span>
						</button>
					)}
				</div>
				{uploading && (
					<p role="status" className="text-xs font-semibold text-muted">
						{vi.receipts.uploading}
					</p>
				)}
				{errorText && (
					<p role="alert" className="text-xs font-semibold text-debt">
						{errorText}
					</p>
				)}
			</div>

			<label className="grid gap-1.5">
				<span className="text-xs font-extrabold text-muted">
					{vi.settlementProof.noteLabel}
				</span>
				<input
					type="text"
					maxLength={120}
					value={note}
					placeholder={vi.settlementProof.notePlaceholder}
					onChange={(event) => onNoteChange(event.target.value)}
					className="h-11 min-w-0 w-full rounded-[16px] bg-sunken px-3.5 text-sm font-semibold text-ink"
				/>
			</label>

			{viewingId && (
				<PhotoViewer
					src={attachmentContentUrl(groupId, viewingId)}
					alt={vi.settlementProof.viewProof}
					onClose={() => setViewingId(null)}
				/>
			)}
		</section>
	);
}
