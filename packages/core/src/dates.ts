export const APP_TIME_ZONE = "Asia/Ho_Chi_Minh";

// Vietnam uses UTC+7 year-round with no daylight saving transitions.
const VIETNAM_UTC_OFFSET_MS = 7 * 60 * 60 * 1000;
const CALENDAR_DATE_PATTERN = /^(\d{4})-(\d{2})-(\d{2})$/;

function parseCalendarParts(
	value: string,
): { year: number; month: number; day: number } | null {
	const match = CALENDAR_DATE_PATTERN.exec(value);
	if (!match) return null;
	const year = Number(match[1]);
	const month = Number(match[2]);
	const day = Number(match[3]);
	const date = new Date(Date.UTC(year, month - 1, day));
	if (
		date.getUTCFullYear() !== year ||
		date.getUTCMonth() + 1 !== month ||
		date.getUTCDate() !== day
	)
		return null;
	return { year, month, day };
}

export function isValidCalendarDate(value: string): boolean {
	return parseCalendarParts(value) !== null;
}

export function isWithinFiveYears(from: string, to: string): boolean {
	const start = parseCalendarParts(from);
	const end = parseCalendarParts(to);
	if (!start || !end) return false;
	if (from > to) return false;
	const maxYear = start.year + 5;
	const limit = `${String(maxYear).padStart(4, "0")}-${String(start.month).padStart(2, "0")}-${String(start.day).padStart(2, "0")}`;
	return to <= limit;
}

export function toVietnamDate(date: Date): string {
	const shifted = new Date(date.getTime() + VIETNAM_UTC_OFFSET_MS);
	return shifted.toISOString().slice(0, 10);
}

export function formatVietnamDateTime(date: Date): string {
	const shifted = new Date(date.getTime() + VIETNAM_UTC_OFFSET_MS);
	return shifted.toISOString().slice(0, 16).replace("T", " ");
}

function monthRange(
	year: number,
	month: number,
): { start: string; end: string } {
	const lastDay = new Date(Date.UTC(year, month, 0)).getUTCDate();
	const prefix = `${String(year).padStart(4, "0")}-${String(month).padStart(2, "0")}`;
	return {
		start: `${prefix}-01`,
		end: `${prefix}-${String(lastDay).padStart(2, "0")}`,
	};
}

export function currentMonthRange(now: Date): { start: string; end: string } {
	const parts = parseCalendarParts(toVietnamDate(now));
	if (!parts) throw new RangeError("Invalid Vietnam date");
	return monthRange(parts.year, parts.month);
}

export function previousMonthRange(now: Date): { start: string; end: string } {
	const parts = parseCalendarParts(toVietnamDate(now));
	if (!parts) throw new RangeError("Invalid Vietnam date");
	return parts.month === 1
		? monthRange(parts.year - 1, 12)
		: monthRange(parts.year, parts.month - 1);
}

export function bucketFor(from: string, to: string): "day" | "week" | "month" {
	const start = parseCalendarParts(from);
	const end = parseCalendarParts(to);
	if (!start || !end || from > to)
		throw new RangeError("Invalid date range for bucket");
	const startMs = Date.UTC(start.year, start.month - 1, start.day);
	const endMs = Date.UTC(end.year, end.month - 1, end.day);
	const inclusiveDays = Math.floor((endMs - startMs) / 86_400_000) + 1;
	if (inclusiveDays <= 31) return "day";
	if (inclusiveDays <= 182) return "week";
	return "month";
}

export function localDateRangeToUtc(
	from?: string,
	to?: string,
): { start?: Date; endExclusive?: Date } {
	if (from !== undefined && !isValidCalendarDate(from))
		throw new RangeError("Invalid from date");
	if (to !== undefined && !isValidCalendarDate(to))
		throw new RangeError("Invalid to date");
	if (from !== undefined && to !== undefined && !isWithinFiveYears(from, to))
		throw new RangeError("Invalid date range");
	const fromParts = from === undefined ? null : parseCalendarParts(from);
	const toParts = to === undefined ? null : parseCalendarParts(to);
	return {
		...(fromParts
			? {
					start: new Date(
						Date.UTC(fromParts.year, fromParts.month - 1, fromParts.day) -
							VIETNAM_UTC_OFFSET_MS,
					),
				}
			: {}),
		...(toParts
			? {
					endExclusive: new Date(
						Date.UTC(toParts.year, toParts.month - 1, toParts.day + 1) -
							VIETNAM_UTC_OFFSET_MS,
					),
				}
			: {}),
	};
}
