"use client";
import { useEffect, useRef } from "react";
import { formatAmount, parseAmountInput } from "../../lib/money";
import { vi } from "../../messages/vi";
import { OnlineButton } from "../ui/OnlineButton";
export function AmountField({
	value,
	onChange,
	autoFocus = true,
	label = vi.expenseForm.amountLabel,
}: {
	value: string;
	onChange: (value: string) => void;
	autoFocus?: boolean;
	label?: string;
}) {
	const input = useRef<HTMLInputElement>(null);
	useEffect(() => {
		if (autoFocus) input.current?.focus();
	}, [autoFocus]);
	const change = (text: string) => {
		if (!text.replace(/[^0-9]/g, "")) {
			onChange("");
			return;
		}
		const amount = parseAmountInput(text);
		if (amount !== null) onChange(formatAmount(amount));
	};
	return (
		<div className="flex min-w-0 w-full items-center gap-2 rounded-[32px] border-[3px] border-ink bg-surface px-4 py-2">
			<input
				ref={input}
				aria-label={label}
				inputMode="numeric"
				size={1}
				value={value}
				onChange={(event) => change(event.target.value)}
				className="min-w-0 w-full flex-1 bg-transparent text-center text-[52px] font-black tracking-tight outline-none"
			/>
			<span className="text-[22px] font-black text-muted">
				{vi.common.currency}
			</span>
			<OnlineButton
				type="button"
				onClick={() => change(`${value}000`)}
				className="min-h-11 min-w-11 rounded-pill bg-sunken text-xs font-bold"
			>
				{vi.expenseForm.addThousands}
			</OnlineButton>
		</div>
	);
}
