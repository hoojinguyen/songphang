const MAX_AMOUNT = 999_999_999_999n;
function money(value: bigint): number | null {
	return value > 0n && value <= MAX_AMOUNT ? Number(value) : null;
}
export function readAmount(value: string, personal = false): number | null {
	const token = value.replace(/\s+/g, "");
	const million = /^(\d+)(?:[.,](\d{1,6}))?(?:tr|trieu)(\d{1,6})?$/.exec(token);
	if (million) {
		const whole = million[1];
		const decimals = million[2] ?? million[3] ?? "";
		if (whole === undefined || (million[2] && million[3])) return null;
		return money(BigInt(whole) * 1_000_000n + BigInt(decimals.padEnd(6, "0")));
	}
	const thousand = /^(\d+)(?:k|nghin|ngan)$/.exec(token);
	if (thousand?.[1]) return money(BigInt(thousand[1]) * 1000n);
	if (/^\d{1,3}(\.\d{3})+$/.test(token))
		return money(BigInt(token.replaceAll(".", "")));
	if (!/^\d+$/.test(token)) return null;
	const number = BigInt(token);
	return number >= 1000n
		? money(number)
		: personal
			? money(number * 1000n)
			: null;
}
