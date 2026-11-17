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
