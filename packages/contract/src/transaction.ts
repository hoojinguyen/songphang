import { z } from "@hono/zod-openapi";
import { isValidCalendarDate, isWithinFiveYears } from "@songphang/core";
export const MoneyAmount = z.int().min(1).max(999_999_999_999);
export const CalendarDate = z
	.string()
	.regex(/^\d{4}-\d{2}-\d{2}$/)
	.refine(isValidCalendarDate);
export const TransactionCategory = z.enum([
	"food",
	"transport",
	"lodging",
	"shopping",
	"entertainment",
	"bills",
	"other",
]);
const MemberIds = z
	.array(z.uuid())
	.min(1)
	.max(100)
	.refine((ids) => new Set(ids).size === ids.length);
export const EqualSplitInput = z.object({
	method: z.literal("equal"),
	members: MemberIds,
});
export type EqualSplitInput = z.infer<typeof EqualSplitInput>;
const ExactSplitInput = z
	.object({
		method: z.literal("exact"),
		members: MemberIds,
		entries: z
			.array(z.object({ memberId: z.uuid(), amount: MoneyAmount }))
			.max(100),
		remainder: z.enum(["none", "equal_among_blank", "equal_among_all"]),
	})
	.refine(
		(split) =>
			new Set(split.entries.map((e) => e.memberId)).size ===
				split.entries.length &&
			split.entries.every((e) => split.members.includes(e.memberId)) &&
			(split.remainder !== "none" ||
				split.entries.length === split.members.length),
	);
const SharesSplitInput = z
	.object({
		method: z.literal("shares"),
		entries: z
			.array(
				z.object({
					memberId: z.uuid(),
					weight: z.string().regex(/^\d{1,4}(\.\d{1,2})?$/),
				}),
			)
			.min(1)
			.max(100),
	})
	.refine(
		(split) =>
			new Set(split.entries.map((e) => e.memberId)).size ===
			split.entries.length,
	);
const PercentSplitInput = z
	.object({
		method: z.literal("percent"),
		entries: z
			.array(
				z.object({
					memberId: z.uuid(),
					percent: z.string().regex(/^\d{1,3}(\.\d{1,2})?$/),
				}),
			)
			.min(1)
			.max(100),
	})
	.refine(
		(split) =>
			new Set(split.entries.map((e) => e.memberId)).size ===
			split.entries.length,
	);
export const SplitInput = z
	.discriminatedUnion("method", [
		EqualSplitInput,
		ExactSplitInput,
		SharesSplitInput,
		PercentSplitInput,
	])
	.openapi("SplitInput");
export type SplitInput = z.infer<typeof SplitInput>;
const Payers = z
	.array(z.object({ memberId: z.uuid(), amount: MoneyAmount }))
	.min(1)
	.max(100)
	.refine(
		(payers) => new Set(payers.map((p) => p.memberId)).size === payers.length,
	);
const LedgerFields = {
	description: z.string().trim().min(1).max(200),
	amount: MoneyAmount,
	occurredAt: z.iso.datetime(),
	category: TransactionCategory.nullable(),
	categoryId: z.uuid().nullable().default(null),
	payers: Payers,
	split: SplitInput,
};
export const SplitTransactionRequest = z
	.object({ type: z.enum(["expense", "income"]), ...LedgerFields })
	.refine(
		(request) => !(request.category !== null && request.categoryId !== null),
	)
	.openapi("SplitTransactionRequest");
export type SplitTransactionRequest = z.infer<typeof SplitTransactionRequest>;
export const TransferRequest = z
	.object({
		type: z.literal("transfer"),
		amount: MoneyAmount,
		occurredAt: z.iso.datetime(),
		fromMemberId: z.uuid(),
		toMemberId: z.uuid(),
		description: z.string().trim().min(1).max(200).optional(),
	})
	.refine((request) => request.fromMemberId !== request.toMemberId)
	.openapi("TransferRequest");
export const CreateTransactionRequest = z
	.discriminatedUnion("type", [SplitTransactionRequest, TransferRequest])
	.openapi("CreateTransactionRequest");
export type CreateTransactionRequest = z.infer<typeof CreateTransactionRequest>;
export const ShareDto = z.object({
	memberId: z.uuid(),
	amount: z.int().nonnegative(),
});
export const TransactionDto = z
	.object({
		type: z.enum(["expense", "income", "transfer"]),
		...LedgerFields,
		id: z.uuid(),
		currency: z.literal("VND"),
		shares: z.array(ShareDto),
		version: z.int().positive(),
		updatedBy: z.object({ id: z.uuid(), name: z.string() }).nullable(),
		createdBy: z.object({ id: z.uuid(), name: z.string() }).nullable(),
		createdAt: z.iso.datetime(),
		updatedAt: z.iso.datetime(),
		deletedAt: z.iso.datetime().nullable(),
	})
	.openapi("TransactionDto");
export type TransactionDto = z.infer<typeof TransactionDto>;
export const TransactionWarning = z.enum([
	"FUND_OVERDRAWN",
	"BUDGET_NEAR",
	"BUDGET_OVER",
]);
export type TransactionWarning = z.infer<typeof TransactionWarning>;
export const TransactionResponse = z
	.object({
		transaction: TransactionDto,
		warnings: z.array(TransactionWarning).default([]),
	})
	.openapi("TransactionResponse");
export const PreviewTransactionRequest = z
	.intersection(
		SplitTransactionRequest,
		z.object({ transactionId: z.uuid().optional() }),
	)
	.openapi("PreviewTransactionRequest");
export type PreviewTransactionRequest = z.infer<
	typeof PreviewTransactionRequest
>;
export const PreviewTransactionResponse = z
	.object({
		shares: z.array(ShareDto),
		warnings: z.array(TransactionWarning).default([]),
	})
	.openapi("PreviewTransactionResponse");
export const TransactionsQuery = z
	.object({
		cursor: z.string().max(512).optional(),
		limit: z.coerce.number().int().min(1).max(200).default(50),
		q: z.string().trim().min(1).max(100).optional(),
		memberId: z.uuid().optional(),
		category: TransactionCategory.optional(),
		categoryId: z.uuid().optional(),
		uncategorized: z.enum(["true", "false"]).optional(),
		spendingOnly: z.enum(["true", "false"]).optional(),
		type: z.enum(["expense", "transfer", "income"]).optional(),
		from: CalendarDate.optional(),
		to: CalendarDate.optional(),
	})
	.refine(
		(query) =>
			!(query.spendingOnly === "true" && query.type === "transfer") &&
			!(
				query.uncategorized === "true" &&
				(query.category !== undefined || query.categoryId !== undefined)
			) &&
			(query.from === undefined ||
				query.to === undefined ||
				isWithinFiveYears(query.from, query.to)),
	);
export type TransactionsQuery = z.infer<typeof TransactionsQuery>;
export const TransactionsResponse = z
	.object({
		transactions: z.array(TransactionDto),
		nextCursor: z.string().nullable(),
	})
	.openapi("TransactionsResponse");

export const UpdateTransactionRequest = z.intersection(
	CreateTransactionRequest,
	z.object({ version: z.int().positive() }),
);
export type UpdateTransactionRequest = z.infer<typeof UpdateTransactionRequest>;
