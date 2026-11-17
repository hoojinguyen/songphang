import { z } from "@hono/zod-openapi";
import { CalendarDate, MoneyAmount } from "./transaction.ts";

export const BudgetPeriod = z.enum(["month", "total"]);
export type BudgetPeriod = z.infer<typeof BudgetPeriod>;

export const BudgetStateSchema = z.enum(["ok", "near", "over"]);
export type BudgetStateDto = z.infer<typeof BudgetStateSchema>;

export const PutBudgetRequest = z
	.object({
		period: BudgetPeriod,
		amount: MoneyAmount,
	})
	.openapi("PutBudgetRequest");
export type PutBudgetRequest = z.infer<typeof PutBudgetRequest>;

export const BudgetDto = z
	.object({
		period: BudgetPeriod,
		amount: MoneyAmount,
		spent: z.int(),
		state: BudgetStateSchema,
		periodStart: CalendarDate.nullable(),
		periodEnd: CalendarDate.nullable(),
	})
	.openapi("BudgetDto");
export type BudgetDto = z.infer<typeof BudgetDto>;

export const BudgetResponse = z
	.object({ budget: BudgetDto.nullable() })
	.openapi("BudgetResponse");
export type BudgetResponse = z.infer<typeof BudgetResponse>;
