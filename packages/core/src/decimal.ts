export function parseHundredths(text: string): bigint {
	if (!/^\d+(\.\d{1,2})?$/.test(text)) throw new RangeError("Invalid decimal");
	const [whole, fraction = ""] = text.split(".");
	if (whole === undefined) throw new RangeError("Invalid decimal");
	return BigInt(whole) * 100n + BigInt(fraction.padEnd(2, "0"));
}
