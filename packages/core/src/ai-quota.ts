import {
	currentMonthRange,
	localDateRangeToUtc,
	toVietnamDate,
} from "./dates.ts";

export function quotaWindowStarts(now: Date): {
	dayStart: Date;
	monthStart: Date;
} {
	const day = toVietnamDate(now);
	const month = currentMonthRange(now).start;
	const dayStart = localDateRangeToUtc(day, day).start;
	const monthStart = localDateRangeToUtc(month, month).start;
	if (!dayStart || !monthStart) {
		throw new RangeError("Failed to compute AI quota window starts");
	}
	return { dayStart, monthStart };
}
