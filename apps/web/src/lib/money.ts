import { vi } from "../messages/vi";

const AMOUNT_FORMATTER = new Intl.NumberFormat("vi-VN");
export function formatAmount(amount: number): string {
	return AMOUNT_FORMATTER.format(amount);
}
export function formatMoney(amount: number): string {
	return `${formatAmount(amount)} ${vi.common.currency}`;
}
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
