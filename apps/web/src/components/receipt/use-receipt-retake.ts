"use client";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { ApiError } from "../../lib/api";
import { attachmentContentUrl, uploadAttachment } from "../../lib/attachments";
import { prepareImage } from "../../lib/prepare-image";
import { createReceiptScan } from "../../lib/receipt-scans";
import { vi } from "../../messages/vi";

function uploadErrorMessage(error: unknown): string {
	if (error instanceof ApiError && error.code === "AI_QUOTA_EXCEEDED") {
		return vi.receipts.dailyLimit;
	}
	if (error instanceof Error && error.message === "not an image") {
		return vi.receipts.notAnImage;
	}
	if (error instanceof Error && error.message === "too large") {
		return vi.receipts.fileTooLarge;
	}
	return vi.common.saveError;
}

export function useReceiptRetake(groupId: string) {
	const router = useRouter();
	const [busy, setBusy] = useState(false);
	const [error, setError] = useState<string | null>(null);

	const scanBlob = async (blob: Blob, fileName: string) => {
		const attachment = await uploadAttachment(groupId, blob, fileName);
		const created = await createReceiptScan(
			groupId,
			attachment.id,
			crypto.randomUUID(),
		);
		router.replace(`/g/${groupId}/tx/new?scan=${created.scan.id}`);
	};

	const run = async (work: () => Promise<void>) => {
		if (busy) return;
		setBusy(true);
		setError(null);
		try {
			await work();
		} catch (caught) {
			setError(uploadErrorMessage(caught));
		} finally {
			setBusy(false);
		}
	};

	const scanNewFile = (file: File) =>
		run(async () => {
			let prepared: Blob;
			try {
				prepared = await prepareImage(file);
			} catch {
				setError(vi.receipts.notAnImage);
				return;
			}
			await scanBlob(prepared, file.name || "hoa-don.jpg");
		});

	const rescanAttachment = (attachmentId: string) =>
		run(async () => {
			const response = await fetch(
				attachmentContentUrl(groupId, attachmentId),
				{ credentials: "include", cache: "no-store" },
			);
			if (!response.ok) throw new Error("fetch failed");
			await scanBlob(await response.blob(), "hoa-don.jpg");
		});

	return { busy, error, scanNewFile, rescanAttachment };
}
