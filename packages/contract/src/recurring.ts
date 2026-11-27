import { z } from "@hono/zod-openapi";
import {
	CalendarDate,
	CreateInlineRecurringInput,
	EqualSplitInput,
	MoneyAmount,
	PercentSplitInput,
	SharesSplitInput,
	SplitInput,
	TransactionCategory,
} from "./transaction.ts";

export { CreateInlineRecurringInput };
export const RecurringMode = z.enum(["fixed", "variable"]);
export type RecurringMode = z.infer<typeof RecurringMode>;

export const RecurringFrequency = z.enum([
	"weekly",
	"monthly",
	"quarterly",
	"yearly",
]);
export type RecurringFrequency = z.infer<typeof RecurringFrequency>;

export const RecurringPauseReason = z.enum(["member_invalid", "split_invalid"]);
export type RecurringPauseReason = z.infer<typeof RecurringPauseReason>;

export const RecurringVariableSplitInput = z
	.discriminatedUnion("method", [
		EqualSplitInput,
		SharesSplitInput,
		PercentSplitInput,
	])
	.openapi("RecurringVariableSplitInput");
export type RecurringVariableSplitInput = z.infer<
	typeof RecurringVariableSplitInput
>;

export const RecurringPayerTemplateEntry = z.object({
	memberId: z.uuid(),
	amount: MoneyAmount.optional(),
});
export type RecurringPayerTemplateEntry = z.infer<
	typeof RecurringPayerTemplateEntry
>;

export const RecurringExpenseDto = z
	.object({
		id: z.uuid(),
		groupId: z.uuid(),
		mode: RecurringMode,
		active: z.boolean(),
		description: z.string(),
		amount: MoneyAmount.nullable(),
		category: TransactionCategory.nullable(),
		categoryId: z.uuid().nullable(),
		payersTemplate: z.array(RecurringPayerTemplateEntry).min(1).max(100),
		splitTemplate: SplitInput,
		frequency: RecurringFrequency,
		dayOfWeek: z.int().min(1).max(7).nullable(),
		dayOfMonth: z.int().min(1).max(31).nullable(),
		monthOfYear: z.int().min(1).max(12).nullable(),
		nextDueDate: CalendarDate,
		pendingDueDate: CalendarDate.nullable(),
		lastProcessedDueDate: CalendarDate.nullable(),
		lastPostedAt: z.iso.datetime().nullable(),
		lastTransactionId: z.uuid().nullable(),
		pauseReason: RecurringPauseReason.nullable(),
		createdAt: z.iso.datetime(),
		updatedAt: z.iso.datetime(),
	})
	.openapi("RecurringExpenseDto");
export type RecurringExpenseDto = z.infer<typeof RecurringExpenseDto>;

export const RecurringExpensesResponse = z
	.object({ recurringExpenses: z.array(RecurringExpenseDto) })
	.openapi("RecurringExpensesResponse");
export type RecurringExpensesResponse = z.infer<
	typeof RecurringExpensesResponse
>;

export const RecurringExpenseResponse = z
	.object({ recurringExpense: RecurringExpenseDto })
	.openapi("RecurringExpenseResponse");
export type RecurringExpenseResponse = z.infer<typeof RecurringExpenseResponse>;

function hasValidScheduleFields(input: {
	frequency: RecurringFrequency;
	dayOfWeek?: number | null | undefined;
	dayOfMonth?: number | null | undefined;
	monthOfYear?: number | null | undefined;
}): boolean {
	if (input.frequency === "weekly") {
		return (
			input.dayOfWeek !== undefined &&
			input.dayOfWeek !== null &&
			(input.dayOfMonth === undefined || input.dayOfMonth === null) &&
			(input.monthOfYear === undefined || input.monthOfYear === null)
		);
	}
	if (input.frequency === "monthly" || input.frequency === "quarterly") {
		return (
			input.dayOfMonth !== undefined &&
			input.dayOfMonth !== null &&
			(input.dayOfWeek === undefined || input.dayOfWeek === null) &&
			(input.monthOfYear === undefined || input.monthOfYear === null)
		);
	}
	return (
		input.dayOfMonth !== undefined &&
		input.dayOfMonth !== null &&
		input.monthOfYear !== undefined &&
		input.monthOfYear !== null &&
		(input.dayOfWeek === undefined || input.dayOfWeek === null)
	);
}

const RecurringPayersTemplate = z
	.array(RecurringPayerTemplateEntry)
	.min(1)
	.max(100)
	.refine(
		(payers) => new Set(payers.map((p) => p.memberId)).size === payers.length,
	);

export const CreateRecurringExpenseRequest = z
	.object({
		mode: RecurringMode,
		description: z.string().trim().min(1).max(200),
		amount: MoneyAmount.nullable().optional(),
		category: TransactionCategory.nullable().default(null),
		categoryId: z.uuid().nullable().default(null),
		payersTemplate: RecurringPayersTemplate,
		splitTemplate: SplitInput,
		frequency: RecurringFrequency,
		dayOfWeek: z.int().min(1).max(7).nullable().optional(),
		dayOfMonth: z.int().min(1).max(31).nullable().optional(),
		monthOfYear: z.int().min(1).max(12).nullable().optional(),
	})
	.refine((request) => {
		if (request.category !== null && request.categoryId !== null) return false;
		if (!hasValidScheduleFields(request)) return false;
		if (request.mode === "fixed") {
			return (
				request.amount !== undefined &&
				request.amount !== null &&
				request.payersTemplate.every((payer) => payer.amount !== undefined)
			);
		}
		return (
			request.payersTemplate.length === 1 &&
			(request.splitTemplate.method === "equal" ||
				request.splitTemplate.method === "shares" ||
				request.splitTemplate.method === "percent")
		);
	})
	.openapi("CreateRecurringExpenseRequest");
export type CreateRecurringExpenseRequest = z.infer<
	typeof CreateRecurringExpenseRequest
>;

export const UpdateRecurringExpenseRequest = z
	.object({
		mode: RecurringMode.optional(),
		active: z.boolean().optional(),
		description: z.string().trim().min(1).max(200).optional(),
		amount: MoneyAmount.nullable().optional(),
		category: TransactionCategory.nullable().optional(),
		categoryId: z.uuid().nullable().optional(),
		payersTemplate: RecurringPayersTemplate.optional(),
		splitTemplate: SplitInput.optional(),
		frequency: RecurringFrequency.optional(),
		dayOfWeek: z.int().min(1).max(7).nullable().optional(),
		dayOfMonth: z.int().min(1).max(31).nullable().optional(),
		monthOfYear: z.int().min(1).max(12).nullable().optional(),
	})
	.refine(
		(request) =>
			Object.keys(request).length > 0 &&
			!(
				request.category !== undefined &&
				request.category !== null &&
				request.categoryId !== undefined &&
				request.categoryId !== null
			),
	)
	.openapi("UpdateRecurringExpenseRequest");
export type UpdateRecurringExpenseRequest = z.infer<
	typeof UpdateRecurringExpenseRequest
>;
