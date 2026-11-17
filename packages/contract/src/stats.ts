import { z } from "@hono/zod-openapi";
import { isWithinFiveYears } from "@songphang/core";
import { CalendarDate, TransactionCategory } from "./transaction.ts";

export const StatsQuery = z
	.object({
		from: CalendarDate.optional(),
		to: CalendarDate.optional(),
	})
	.refine(
		(query) =>
			query.from === undefined ||
			query.to === undefined ||
			isWithinFiveYears(query.from, query.to),
	);
export type StatsQuery = z.infer<typeof StatsQuery>;

export const StatsBucket = z.enum(["day", "week", "month"]);

export const StatsResponse = z
	.object({
		from: CalendarDate,
		to: CalendarDate,
		bucket: StatsBucket,
		total: z.int(),
		byCategory: z.array(
			z.object({
				category: TransactionCategory.nullable(),
				categoryId: z.uuid().nullable(),
				amount: z.int(),
			}),
		),
		byMember: z.array(
			z.object({
				memberId: z.uuid(),
				paid: z.int(),
				share: z.int(),
			}),
		),
		byBucket: z.array(
			z.object({
				start: CalendarDate,
				amount: z.int(),
			}),
		),
	})
	.openapi("StatsResponse");
export type StatsResponse = z.infer<typeof StatsResponse>;
