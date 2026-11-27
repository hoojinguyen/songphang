import { isValidCalendarDate, toVietnamDate } from "./dates.ts";

export type RecurringSchedule =
	| { frequency: "weekly"; dayOfWeek: number }
	| { frequency: "monthly"; dayOfMonth: number }
	| { frequency: "quarterly"; dayOfMonth: number }
	| { frequency: "yearly"; monthOfYear: number; dayOfMonth: number };

const VIETNAM_UTC_OFFSET_MS = 7 * 60 * 60 * 1000;

function parseDateParts(dateStr: string): {
	year: number;
	month: number;
	day: number;
} {
	if (!isValidCalendarDate(dateStr)) {
		throw new RangeError(`Invalid calendar date: ${dateStr}`);
	}
	const [y, m, d] = dateStr.split("-").map(Number);
	if (y === undefined || m === undefined || d === undefined) {
		throw new RangeError(`Invalid calendar date: ${dateStr}`);
	}
	return { year: y, month: m, day: d };
}

function formatDateParts(year: number, month: number, day: number): string {
	return `${String(year).padStart(4, "0")}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
}

function daysInMonth(year: number, month: number): number {
	return new Date(Date.UTC(year, month, 0)).getUTCDate();
}

function addMonths(
	year: number,
	month: number,
	deltaMonths: number,
): { year: number; month: number } {
	const totalMonths = year * 12 + (month - 1) + deltaMonths;
	const nextYear = Math.floor(totalMonths / 12);
	const nextMonth = (totalMonths % 12) + 1;
	return { year: nextYear, month: nextMonth };
}

function isAfterCutoff(
	candidate: string,
	afterDateVN: string,
	inclusive: boolean,
): boolean {
	return inclusive ? candidate >= afterDateVN : candidate > afterDateVN;
}

export function todayInVietnam(now: Date): string {
	return toVietnamDate(now);
}

export function hourInVietnam(now: Date): number {
	const shifted = new Date(now.getTime() + VIETNAM_UTC_OFFSET_MS);
	return shifted.getUTCHours();
}

export function computeNextDueDate(
	schedule: RecurringSchedule,
	afterDateVN: string,
	inclusive = false,
): string {
	const { year, month, day } = parseDateParts(afterDateVN);

	if (schedule.frequency === "weekly") {
		if (
			!Number.isInteger(schedule.dayOfWeek) ||
			schedule.dayOfWeek < 1 ||
			schedule.dayOfWeek > 7
		) {
			throw new RangeError("dayOfWeek must be an integer between 1 and 7");
		}
		const baseUtcMs = Date.UTC(year, month - 1, day + (inclusive ? 0 : 1));
		const baseDate = new Date(baseUtcMs);
		const isoDow = ((baseDate.getUTCDay() + 6) % 7) + 1;
		const deltaDays = (schedule.dayOfWeek - isoDow + 7) % 7;
		const target = new Date(baseUtcMs + deltaDays * 86_400_000);
		return formatDateParts(
			target.getUTCFullYear(),
			target.getUTCMonth() + 1,
			target.getUTCDate(),
		);
	}

	if (schedule.frequency === "monthly" || schedule.frequency === "quarterly") {
		if (
			!Number.isInteger(schedule.dayOfMonth) ||
			schedule.dayOfMonth < 1 ||
			schedule.dayOfMonth > 31
		) {
			throw new RangeError("dayOfMonth must be an integer between 1 and 31");
		}
		const stepMonths = schedule.frequency === "monthly" ? 1 : 3;
		const candidate = formatDateParts(
			year,
			month,
			Math.min(schedule.dayOfMonth, daysInMonth(year, month)),
		);
		if (isAfterCutoff(candidate, afterDateVN, inclusive)) {
			return candidate;
		}
		const next = addMonths(year, month, stepMonths);
		return formatDateParts(
			next.year,
			next.month,
			Math.min(schedule.dayOfMonth, daysInMonth(next.year, next.month)),
		);
	}

	if (
		!Number.isInteger(schedule.monthOfYear) ||
		schedule.monthOfYear < 1 ||
		schedule.monthOfYear > 12 ||
		!Number.isInteger(schedule.dayOfMonth) ||
		schedule.dayOfMonth < 1 ||
		schedule.dayOfMonth > 31
	) {
		throw new RangeError("Invalid yearly schedule fields");
	}
	const thisYearCandidate = formatDateParts(
		year,
		schedule.monthOfYear,
		Math.min(schedule.dayOfMonth, daysInMonth(year, schedule.monthOfYear)),
	);
	if (isAfterCutoff(thisYearCandidate, afterDateVN, inclusive)) {
		return thisYearCandidate;
	}
	const nextYear = year + 1;
	return formatDateParts(
		nextYear,
		schedule.monthOfYear,
		Math.min(schedule.dayOfMonth, daysInMonth(nextYear, schedule.monthOfYear)),
	);
}
