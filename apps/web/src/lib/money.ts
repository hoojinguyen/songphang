import { formatAmount, formatMoney } from "@songphang/core";

export { formatAmount, formatMoney };

export function formatSignedAmount(amount: number): string {
	return amount === 0
		? "0"
		: `${amount > 0 ? "+" : "−"}${formatAmount(Math.abs(amount))}`;
}
export function formatCompactAmount(amount: number): string {
	return amount % 1000 === 0
		? String(amount).slice(0, -3) || "0"
		: formatAmount(amount);
}

export function parseAmountInput(text: string): number | null {
	const digits = text.replace(/[^0-9]/g, "");
	if (digits.length === 0) return null;
	const amount = Number(digits);
	return Number.isSafeInteger(amount) && amount <= 999_999_999_999
		? amount
		: null;
}
