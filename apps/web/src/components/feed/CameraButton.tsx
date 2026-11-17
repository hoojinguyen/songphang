"use client";
import { useRouter } from "next/navigation";
import { type ChangeEvent, useEffect, useId, useRef, useState } from "react";
import { ApiError } from "../../lib/api";
import { uploadAttachment } from "../../lib/attachments";
import { prepareImage } from "../../lib/prepare-image";
import { createReceiptScan } from "../../lib/receipt-scans";
import { vi } from "../../messages/vi";
import { Icon } from "../ui/Icon";

function uploadErrorMessage(error: unknown): string {
	if (error instanceof Error) {
		if (error.message === "not an image") return vi.receipts.notAnImage;
		if (error.message === "too large") return vi.receipts.fileTooLarge;
	}
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
		if (error.code === "RATE_LIMITED") {
			return vi.attachments.rateLimited;
		}
		if (error.code === "AI_QUOTA_EXCEEDED") {
			return vi.receipts.dailyLimit;
		}
	}
	return vi.common.saveError;
}

export function CameraButton({ groupId }: { groupId: string }) {
	const router = useRouter();
	const triggerId = useId();
	const menuId = useId();
	const triggerRef = useRef<HTMLButtonElement>(null);
	const menuRef = useRef<HTMLDivElement>(null);
	const cameraInputRef = useRef<HTMLInputElement>(null);
	const libraryInputRef = useRef<HTMLInputElement>(null);

	const [menuOpen, setMenuOpen] = useState(false);
	const [busy, setBusy] = useState(false);
	const [errorState, setErrorState] = useState<{
		message: string;
		attachmentId?: string;
	} | null>(null);

	useEffect(() => {
		if (!menuOpen) return;
		const onKeyDown = (event: KeyboardEvent) => {
			if (event.key === "Escape") {
				event.preventDefault();
				setMenuOpen(false);
				triggerRef.current?.focus();
			}
		};
		const onPointerDown = (event: PointerEvent) => {
			const target = event.target as Node | null;
			if (
				target &&
				!menuRef.current?.contains(target) &&
				!triggerRef.current?.contains(target)
			) {
				setMenuOpen(false);
			}
		};
		document.addEventListener("keydown", onKeyDown);
		document.addEventListener("pointerdown", onPointerDown);
		return () => {
			document.removeEventListener("keydown", onKeyDown);
			document.removeEventListener("pointerdown", onPointerDown);
		};
	}, [menuOpen]);

	const handleSelect = async (event: ChangeEvent<HTMLInputElement>) => {
		const file = event.target.files?.[0];
		event.target.value = "";
		if (!file || busy) return;
		setMenuOpen(false);
		setErrorState(null);
		setBusy(true);
		let uploadedAttachmentId: string | undefined;
		try {
			let prepared: Blob;
			try {
				prepared = await prepareImage(file);
			} catch {
				setErrorState({ message: vi.receipts.notAnImage });
				return;
			}
			const attachment = await uploadAttachment(
				groupId,
				prepared,
				file.name || "hoa-don.jpg",
			);
			uploadedAttachmentId = attachment.id;
			const result = await createReceiptScan(
				groupId,
				attachment.id,
				crypto.randomUUID(),
			);
			router.push(`/g/${groupId}/tx/new?scan=${result.scan.id}`);
		} catch (error) {
			setErrorState({
				message: uploadErrorMessage(error),
				...(uploadedAttachmentId ? { attachmentId: uploadedAttachmentId } : {}),
			});
		} finally {
			setBusy(false);
		}
	};

	const moveMenuFocus = (direction: 1 | -1 | "first" | "last") => {
		const items = [
			...(menuRef.current?.querySelectorAll<HTMLButtonElement>(
				'[role="menuitem"]',
			) ?? []),
		];
		if (items.length === 0) return;
		if (direction === "first") {
			items[0]?.focus();
			return;
		}
		if (direction === "last") {
			items.at(-1)?.focus();
			return;
		}
		const current = items.indexOf(document.activeElement as HTMLButtonElement);
		const nextIndex =
			current < 0 ? 0 : (current + direction + items.length) % items.length;
		items[nextIndex]?.focus();
	};

	return (
		<div className="relative shrink-0">
			{busy && (
				<p
					role="status"
					className="fixed bottom-24 left-1/2 z-30 -translate-x-1/2 rounded-pill bg-ink px-4 py-2 text-xs font-extrabold text-surface shadow-sm"
				>
					{vi.receipts.uploading}
				</p>
			)}
			{errorState && (
				<div
					role="alert"
					className="fixed bottom-24 left-1/2 z-30 flex w-[calc(100%-40px)] max-w-[390px] -translate-x-1/2 items-center justify-between gap-3 rounded-[20px] bg-coral px-4 py-3 text-xs font-bold text-ink"
				>
					<span>{errorState.message}</span>
					{errorState.attachmentId && (
						<button
							type="button"
							onClick={() =>
								router.push(
									`/g/${groupId}/tx/new?form&attachmentId=${errorState.attachmentId}`,
								)
							}
							className="min-h-11 shrink-0 rounded-pill bg-surface px-3 font-extrabold text-ink"
						>
							{vi.receipts.manualEntry}
						</button>
					)}
				</div>
			)}

			<input
				ref={cameraInputRef}
				type="file"
				accept="image/*"
				capture="environment"
				tabIndex={-1}
				aria-hidden="true"
				onChange={(event) => void handleSelect(event)}
				className="sr-only"
			/>
			<input
				ref={libraryInputRef}
				type="file"
				accept="image/*"
				tabIndex={-1}
				aria-hidden="true"
				onChange={(event) => void handleSelect(event)}
				className="sr-only"
			/>

			<button
				ref={triggerRef}
				id={triggerId}
				type="button"
				disabled={busy}
				aria-label={vi.receipts.cameraLabel}
				aria-haspopup="menu"
				aria-expanded={menuOpen}
				aria-controls={menuOpen ? menuId : undefined}
				onClick={() => setMenuOpen((open) => !open)}
				onKeyDown={(event) => {
					if (event.key === "ArrowDown" || event.key === "ArrowUp") {
						event.preventDefault();
						setMenuOpen(true);
						requestAnimationFrame(() => moveMenuFocus("first"));
					}
				}}
				className="flex size-16 items-center justify-center rounded-[26px] bg-surface text-ink"
			>
				<Icon name="camera" size={24} />
			</button>

			{menuOpen && (
				<div
					ref={menuRef}
					id={menuId}
					role="menu"
					aria-labelledby={triggerId}
					onKeyDown={(event) => {
						if (event.key === "ArrowDown") {
							event.preventDefault();
							moveMenuFocus(1);
						} else if (event.key === "ArrowUp") {
							event.preventDefault();
							moveMenuFocus(-1);
						} else if (event.key === "Home") {
							event.preventDefault();
							moveMenuFocus("first");
						} else if (event.key === "End") {
							event.preventDefault();
							moveMenuFocus("last");
						} else if (event.key === "Tab") {
							setMenuOpen(false);
						}
					}}
					className="absolute bottom-full left-0 z-30 mb-2 grid min-w-[200px] gap-1 rounded-[24px] bg-surface p-2 shadow-lg ring-1 ring-ink/10"
				>
					<button
						type="button"
						role="menuitem"
						onClick={() => cameraInputRef.current?.click()}
						className="flex min-h-12 items-center rounded-[18px] px-4 text-left text-sm font-extrabold text-ink hover:bg-sunken focus-visible:bg-sunken"
					>
						{vi.receipts.takePhoto}
					</button>
					<button
						type="button"
						role="menuitem"
						onClick={() => libraryInputRef.current?.click()}
						className="flex min-h-12 items-center rounded-[18px] px-4 text-left text-sm font-extrabold text-ink hover:bg-sunken focus-visible:bg-sunken"
					>
						{vi.receipts.pickLibrary}
					</button>
				</div>
			)}
		</div>
	);
}
