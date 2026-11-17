"use client";
import { useEffect, useRef } from "react";
import { vi } from "../../messages/vi";
import { Icon } from "./Icon";

export function PhotoViewer({
	src,
	alt,
	onClose,
}: {
	src: string;
	alt: string;
	onClose: () => void;
}) {
	const dialog = useRef<HTMLDialogElement>(null);
	const closeButton = useRef<HTMLButtonElement>(null);

	useEffect(() => {
		const element = dialog.current;
		const opener = document.activeElement;
		element?.showModal();
		closeButton.current?.focus();
		return () => {
			element?.close();
			if (opener instanceof HTMLElement && opener.isConnected) opener.focus();
		};
	}, []);

	return (
		<dialog
			ref={dialog}
			aria-label={alt}
			onCancel={(event) => {
				event.preventDefault();
				onClose();
			}}
			onKeyDown={(event) => {
				if (event.key === "Escape") {
					event.preventDefault();
					onClose();
				}
			}}
			onClick={(event) => {
				if (event.target === dialog.current) onClose();
			}}
			className="m-auto max-h-dvh w-full max-w-[430px] overscroll-contain bg-transparent p-4 text-surface backdrop:bg-ink/85"
		>
			<div className="flex flex-col items-end gap-3">
				<button
					ref={closeButton}
					type="button"
					onClick={onClose}
					aria-label={vi.attachments.closePhoto}
					className="flex h-11 w-11 items-center justify-center rounded-full bg-surface text-ink"
				>
					<Icon name="close" size={20} />
				</button>
				<img
					src={src}
					alt={alt}
					className="mx-auto max-h-[80dvh] w-auto max-w-full rounded-[20px] object-contain"
				/>
			</div>
		</dialog>
	);
}
