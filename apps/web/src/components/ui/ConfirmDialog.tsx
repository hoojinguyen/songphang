"use client";
import { type ReactNode, useEffect, useId, useRef } from "react";
import { Button } from "./Button";
export function ConfirmDialog({
	title,
	body,
	confirmLabel,
	cancelLabel,
	onConfirm,
	onCancel,
	confirmDisabled,
	children,
}: {
	title: string;
	body: string;
	confirmLabel: string;
	cancelLabel: string;
	onConfirm: () => void;
	onCancel: () => void;
	confirmDisabled?: boolean;
	children?: ReactNode;
}) {
	const dialog = useRef<HTMLDialogElement>(null);
	const cancel = useRef<HTMLButtonElement>(null);
	const titleId = useId();
	const bodyId = useId();
	useEffect(() => {
		const element = dialog.current;
		const opener = document.activeElement;
		element?.showModal();
		cancel.current?.focus();
		return () => {
			element?.close();
			if (opener instanceof HTMLElement && opener.isConnected) opener.focus();
		};
	}, []);
	return (
		<dialog
			ref={dialog}
			aria-labelledby={titleId}
			aria-describedby={bodyId}
			onCancel={(event) => {
				event.preventDefault();
				onCancel();
			}}
			className="m-auto w-[calc(100%-40px)] max-w-[390px] rounded-[30px] bg-bg p-6 text-ink backdrop:bg-ink/40"
		>
			<h2 id={titleId} className="text-xl font-black">
				{title}
			</h2>
			<p id={bodyId} className="my-4 text-sm">
				{body}
			</p>
			{children}
			<div className="mt-5 grid grid-cols-2 gap-3">
				<button
					ref={cancel}
					type="button"
					onClick={onCancel}
					className="min-h-11 rounded-pill bg-surface px-4 font-bold"
				>
					{cancelLabel}
				</button>
				<Button
					variant="primary"
					onClick={onConfirm}
					disabled={confirmDisabled}
				>
					{confirmLabel}
				</Button>
			</div>
		</dialog>
	);
}
