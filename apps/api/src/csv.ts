const FORMULA_PREFIX = /^[=+\-@\t\r]/;
const NEEDS_QUOTES = /[",\r\n]/;

export function csvCell(value: string | number): string {
	if (typeof value === "number") return String(value);
	const safe = FORMULA_PREFIX.test(value) ? `'${value}` : value;
	return NEEDS_QUOTES.test(safe) ? `"${safe.replaceAll('"', '""')}"` : safe;
}

export function serializeCsv(
	rows: ReadonlyArray<ReadonlyArray<string | number>>,
) {
	const lines = rows.map((row) => row.map(csvCell).join(","));
	return `\uFEFF${lines.join("\r\n")}\r\n`;
}
