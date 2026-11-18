const AMOUNT_FORMATTER = new Intl.NumberFormat("vi-VN");

export function formatAmount(amount: number): string {
	return AMOUNT_FORMATTER.format(amount);
}

export function formatMoney(amount: number): string {
	return `${formatAmount(amount)} đ`;
}
