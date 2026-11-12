import { z } from "@hono/zod-openapi";
export const MoneyAmount = z.int().min(1).max(999_999_999_999);
export const TransactionCategory = z.enum([
	"food",
	"transport",
	"lodging",
	"shopping",
	"entertainment",
	"bills",
	"other",
]);
export const EqualSplitInput = z.object({
	method: z.literal("equal"),
	members: z
		.array(z.uuid())
		.min(1)
		.max(100)
		.refine((ids) => new Set(ids).size === ids.length),
});
export type EqualSplitInput = z.infer<typeof EqualSplitInput>;
export const CreateTransactionRequest = z
	.object({
		type: z.literal("expense"),
		description: z.string().trim().min(1).max(200),
		amount: MoneyAmount,
		occurredAt: z.iso.datetime(),
		category: TransactionCategory.nullable(),
		payers: z
			.array(z.object({ memberId: z.uuid(), amount: MoneyAmount }))
			.length(1),
		split: EqualSplitInput,
	})
	.openapi("CreateTransactionRequest");
export type CreateTransactionRequest = z.infer<typeof CreateTransactionRequest>;
export const ShareDto = z.object({
	memberId: z.uuid(),
	amount: z.int().nonnegative(),
});
export const TransactionDto = CreateTransactionRequest.extend({
	id: z.uuid(),
	currency: z.literal("VND"),
	shares: z.array(ShareDto),
	version: z.int().positive(),
	createdBy: z.object({ id: z.uuid(), name: z.string() }),
	createdAt: z.iso.datetime(),
	updatedAt: z.iso.datetime(),
	deletedAt: z.iso.datetime().nullable(),
}).openapi("TransactionDto");
export type TransactionDto = z.infer<typeof TransactionDto>;
export const TransactionResponse = z
	.object({ transaction: TransactionDto })
	.openapi("TransactionResponse");
export const PreviewTransactionResponse = z
	.object({ shares: z.array(ShareDto) })
	.openapi("PreviewTransactionResponse");
export const TransactionsQuery = z.object({
	cursor: z.string().max(512).optional(),
	limit: z.coerce.number().int().min(1).max(200).default(50),
});
export type TransactionsQuery = z.infer<typeof TransactionsQuery>;
export const TransactionsResponse = z
	.object({
		transactions: z.array(TransactionDto),
		nextCursor: z.string().nullable(),
	})
	.openapi("TransactionsResponse");
