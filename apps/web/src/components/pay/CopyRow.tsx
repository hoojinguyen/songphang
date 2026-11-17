"use client";
import { useEffect, useRef, useState } from "react";
import { vi } from "../../messages/vi";

export function CopyRow({
	label,
	value,
	copyValue = value,
	buttonLabel = vi.pay.copy,
	compact = false,
}: {
	label: string;
	value: string;
	copyValue?: string;
	buttonLabel?: string;
	compact?: boolean;
}) {
	const [copied, setCopied] = useState(false);
	const [announcement, setAnnouncement] = useState("");
	const valueRef = useRef<HTMLSpanElement>(null);
	const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
	const lastAnnouncementRef = useRef("");

	useEffect(
		() => () => {
			if (timerRef.current) clearTimeout(timerRef.current);
		},
		[],
	);

	function selectFallback() {
		const element = valueRef.current;
		const selection = window.getSelection();
		if (!element || !selection) return;
		const range = document.createRange();
		range.selectNodeContents(element);
		selection.removeAllRanges();
		selection.addRange(range);
	}

	function announceCopied() {
		let message = vi.pay.copied;
		if (message === lastAnnouncementRef.current) message += "\u00A0";
		lastAnnouncementRef.current = message;
		setAnnouncement(message);
	}

	async function handleCopy() {
		if (timerRef.current) clearTimeout(timerRef.current);
		if (typeof navigator.clipboard?.writeText !== "function") {
			selectFallback();
			return;
		}
		try {
			await navigator.clipboard.writeText(copyValue);
			setCopied(true);
			announceCopied();
			timerRef.current = setTimeout(() => {
				setCopied(false);
				setAnnouncement("");
			}, 2000);
		} catch {
			selectFallback();
		}
	}

	if (compact) {
		return (
			<div className="flex items-center justify-center gap-2">
				<span ref={valueRef} className="sr-only">
					{copyValue}
				</span>
				<button
					type="button"
					onClick={() => void handleCopy()}
					className="min-h-11 rounded-pill bg-surface px-4 text-xs font-bold text-ink"
				>
					{copied ? vi.pay.copied : buttonLabel}
				</button>
				<span role="status" className="sr-only">
					{announcement}
				</span>
			</div>
		);
	}

	return (
		<div className="flex items-center justify-between gap-3 py-1">
			<div className="min-w-0 flex-1">
				{label && <p className="text-xs text-muted">{label}</p>}
				<span
					ref={valueRef}
					className="block break-all text-sm font-bold text-ink"
				>
					{value}
				</span>
			</div>
			<button
				type="button"
				onClick={() => void handleCopy()}
				className="min-h-11 shrink-0 rounded-pill bg-sunken px-3 text-xs font-bold text-ink"
			>
				{copied ? vi.pay.copied : buttonLabel}
				{!copied && label && <span className="sr-only"> {label}</span>}
			</button>
			<span role="status" className="sr-only">
				{announcement}
			</span>
		</div>
	);
}
