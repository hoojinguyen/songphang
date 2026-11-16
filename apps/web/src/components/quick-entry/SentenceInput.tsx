"use client";
import type { ParseResponse } from "@songphang/contract";
import { useEffect, useId, useRef } from "react";
import { vi } from "../../messages/vi";
import { HighlightedSentence } from "./HighlightedSentence";
export function SentenceInput({
	text,
	spans,
	onChange,
	onSend,
}: {
	text: string;
	spans: ParseResponse["spans"];
	onChange: (s: string) => void;
	onSend: () => void;
}) {
	const highlightsId = useId();
	const ref = useRef<HTMLTextAreaElement>(null);
	useEffect(() => {
		ref.current?.focus();
	}, []);
	return (
		<div className="relative min-w-0 flex-1 text-base leading-[1.8]">
			<div
				aria-hidden="true"
				className="pointer-events-none whitespace-pre-wrap break-words px-1 py-2"
			>
				<HighlightedSentence text={text || " "} spans={spans} />
			</div>
			<p id={highlightsId} className="sr-only" aria-live="polite">
				<HighlightedSentence text={text} spans={spans} />
			</p>
			<textarea
				aria-describedby={highlightsId}
				ref={ref}
				aria-label={vi.compose.inputLabel}
				maxLength={300}
				value={text}
				rows={2}
				onChange={(e) =>
					onChange(e.target.value.normalize("NFC").replace(/[\r\n]+/g, " "))
				}
				onPaste={(e) => {
					e.preventDefault();
					const el = e.currentTarget;
					const pasted = e.clipboardData
						.getData("text")
						.normalize("NFC")
						.replace(/[\r\n]+/g, " ");
					onChange(
						(
							text.slice(0, el.selectionStart) +
							pasted +
							text.slice(el.selectionEnd)
						).slice(0, 300),
					);
				}}
				onKeyDown={(e) => {
					if (e.key === "Enter" && !e.nativeEvent.isComposing) {
						e.preventDefault();
						if (!e.shiftKey) onSend();
					}
				}}
				className="absolute inset-0 h-full w-full resize-none overflow-hidden bg-transparent px-1 py-2 text-transparent caret-ink"
			/>
		</div>
	);
}
