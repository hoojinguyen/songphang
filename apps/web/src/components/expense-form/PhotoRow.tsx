"use client";
import type { AttachmentDto } from "@songphang/contract";
import { useRef, useState } from "react";
import { ApiError } from "../../lib/api";
import { attachmentContentUrl, uploadAttachment } from "../../lib/attachments";
import { prepareImage } from "../../lib/prepare-image";
import { vi } from "../../messages/vi";
import { Icon } from "../ui/Icon";
import { PhotoViewer } from "../ui/PhotoViewer";

const MAX_ATTACHMENTS = 3;

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
		return vi.common.saveError;
	}
	return vi.receipts.notAnImage;
}

export function PhotoRow({
	groupId,
	attachments,
	onAdd,
	onRemove,
	readOnly = false,
}: {
	groupId: string;
	attachments: AttachmentDto[];
	onAdd?: (attachment: AttachmentDto) => void;
	onRemove?: (id: string) => void;
	readOnly?: boolean;
}) {
	const inputRef = useRef<HTMLInputElement>(null);
	const [uploading, setUploading] = useState(false);
	const [errorText, setErrorText] = useState<string | null>(null);
	const [viewingId, setViewingId] = useState<string | null>(null);

	const handleFiles = async (file: File | undefined) => {
		if (!file || readOnly || !onAdd) return;
		if (attachments.length >= MAX_ATTACHMENTS) {
			setErrorText(vi.attachments.maxLimit);
			return;
		}
		setErrorText(null);
		setUploading(true);
		try {
			const prepared = await prepareImage(file);
			const attachment = await uploadAttachment(groupId, prepared);
			onAdd(attachment);
		} catch (error) {
			setErrorText(mapUploadError(error));
		} finally {
			setUploading(false);
			if (inputRef.current) inputRef.current.value = "";
		}
	};

	const atLimit = attachments.length >= MAX_ATTACHMENTS;

	return (
		<section className="grid gap-2 rounded-[26px] bg-surface p-4">
			<div className="flex items-center justify-between gap-2">
				<span className="text-sm font-extrabold">{vi.attachments.label}</span>
				{!readOnly && (
					<>
						<input
							ref={inputRef}
							type="file"
							accept="image/*"
							className="hidden"
							onChange={(event) => {
								void handleFiles(event.target.files?.[0]);
							}}
						/>
						<button
							type="button"
							disabled={uploading}
							onClick={() => {
								if (atLimit) {
									setErrorText(vi.attachments.maxLimit);
									return;
								}
								inputRef.current?.click();
							}}
							className="flex min-h-11 items-center gap-1.5 rounded-pill bg-sunken px-3.5 text-xs font-bold text-ink disabled:opacity-50"
						>
							<Icon name="plus" size={16} />
							{vi.attachments.add}
						</button>
					</>
				)}
			</div>
			{attachments.length > 0 && (
				<div className="flex flex-wrap gap-3">
					{attachments.map((attachment) => (
						<div key={attachment.id} className="relative">
							<button
								type="button"
								aria-label={vi.attachments.viewPhoto}
								onClick={() => setViewingId(attachment.id)}
								className="block h-16 w-16 overflow-hidden rounded-[16px] bg-sunken"
							>
								<img
									src={attachmentContentUrl(groupId, attachment.id)}
									alt={vi.attachments.label}
									className="h-16 w-16 rounded-[16px] object-cover"
								/>
							</button>
							{!readOnly && onRemove && (
								<button
									type="button"
									aria-label={vi.attachments.removePhoto}
									onClick={() => {
										setErrorText(null);
										onRemove(attachment.id);
									}}
									className="absolute -right-2 -top-2 flex h-11 w-11 items-center justify-center rounded-full"
								>
									<span className="flex h-6 w-6 items-center justify-center rounded-full bg-ink text-surface">
										<Icon name="close" size={14} />
									</span>
								</button>
							)}
						</div>
					))}
				</div>
			)}
			{uploading && (
				<p role="status" className="text-xs font-semibold text-muted">
					{vi.receipts.uploading}
				</p>
			)}
			{!readOnly && atLimit && !errorText && (
				<p className="text-xs font-semibold text-muted">
					{vi.attachments.maxLimit}
				</p>
			)}
			{errorText && (
				<p role="alert" className="text-xs font-semibold text-debt">
					{errorText}
				</p>
			)}
			{viewingId && (
				<PhotoViewer
					src={attachmentContentUrl(groupId, viewingId)}
					alt={vi.attachments.label}
					onClose={() => setViewingId(null)}
				/>
			)}
		</section>
	);
}
