import { z } from "@hono/zod-openapi";
import { isValidCalendarDate, isWithinFiveYears } from "@songphang/core";
import { AttachmentDto } from "./attachment.ts";
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
export const NonnegativeMoneyAmount = z.int().min(0).max(999_999_999_999);
export const ItemsSplitItem = z.object({
	name: z.string().trim().min(1).max(80),
	amount: NonnegativeMoneyAmount,
	memberIds: z
		.array(z.uuid())
		.max(20)
		.refine((ids) => new Set(ids).size === ids.length),
});
export type ItemsSplitItem = z.infer<typeof ItemsSplitItem>;
export const ItemsSplitExtra = z.object({
	kind: z.enum(["tax", "service", "discount", "other"]),
	label: z.string().trim().max(40),
	amount: NonnegativeMoneyAmount,
});
export type ItemsSplitExtra = z.infer<typeof ItemsSplitExtra>;
export const ItemsSplitInput = z.object({
	method: z.literal("items"),
	items: z.array(ItemsSplitItem).min(1).max(60),
	extras: z.array(ItemsSplitExtra).max(6),
});
export type ItemsSplitInput = z.infer<typeof ItemsSplitInput>;
export const SplitInput = z
	.discriminatedUnion("method", [
		EqualSplitInput,
		ExactSplitInput,
		SharesSplitInput,
		PercentSplitInput,
		ItemsSplitInput,
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
const AttachmentIds = z
	.array(z.uuid())
	.max(3)
	.refine((ids) => new Set(ids).size === ids.length);
const LedgerFields = {
	description: z.string().trim().min(1).max(200),
	amount: MoneyAmount,
	occurredAt: z.iso.datetime(),
	category: TransactionCategory.nullable().default(null),
	categoryId: z.uuid().nullable().default(null),
	payers: Payers,
	split: SplitInput,
};
export const SplitTransactionRequest = z
	.object({
		type: z.enum(["expense", "income"]),
		...LedgerFields,
		attachmentIds: AttachmentIds.optional(),
	})
	.refine(
		(request) =>
			!(request.category !== null && request.categoryId !== null) &&
			!(request.type === "income" && request.split.method === "items"),
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
		attachmentIds: AttachmentIds.optional(),
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
export const TransactionDisputeDto = z
	.object({
		id: z.uuid(),
		reason: z.string(),
		openedByName: z.string(),
		openedAt: z.iso.datetime(),
		mine: z.boolean(),
	})
	.openapi("TransactionDisputeDto");
export type TransactionDisputeDto = z.infer<typeof TransactionDisputeDto>;
export const OpenDisputeRequest = z
	.object({
		reason: z.string().trim().min(1).max(500),
	})
	.openapi("OpenDisputeRequest");
export const ApprovalStatus = z.enum([
	"none",
	"pending",
	"approved",
	"rejected",
]);
export type ApprovalStatus = z.infer<typeof ApprovalStatus>;
export const TransactionApprovalDto = z
	.object({
		status: ApprovalStatus,
		decidedByName: z.string().nullable(),
		decidedAt: z.iso.datetime().nullable(),
		note: z.string().nullable(),
	})
	.openapi("TransactionApprovalDto");
export type TransactionApprovalDto = z.infer<typeof TransactionApprovalDto>;
export const ApproveRejectTransactionRequest = z
	.object({
		note: z.string().trim().max(300).optional(),
	})
	.openapi("ApproveRejectTransactionRequest");
export type ApproveRejectTransactionRequest = z.infer<
	typeof ApproveRejectTransactionRequest
>;
export type OpenDisputeRequest = z.infer<typeof OpenDisputeRequest>;
export const DisputeResponse = z
	.object({
		dispute: TransactionDisputeDto.nullable(),
	})
	.openapi("DisputeResponse");
export type DisputeResponse = z.infer<typeof DisputeResponse>;
const BaseTransactionFields = {
	type: z.enum(["expense", "income", "transfer"]),
	...LedgerFields,
	id: z.uuid(),
	currency: z.literal("VND"),
	shares: z.array(ShareDto),
	version: z.int().positive(),
	updatedBy: z.object({ id: z.uuid(), name: z.string() }).nullable(),
	createdBy: z.object({ id: z.uuid(), name: z.string() }).nullable(),
	commentCount: z.int().nonnegative(),
	dispute: TransactionDisputeDto.nullable(),
	approval: TransactionApprovalDto,
	createdAt: z.iso.datetime(),
	updatedAt: z.iso.datetime(),
	deletedAt: z.iso.datetime().nullable(),
};
export const TransactionDto = z
	.object({
		...BaseTransactionFields,
		attachments: z.array(AttachmentDto).max(3),
	})
	.openapi("TransactionDto");
export type TransactionDto = z.infer<typeof TransactionDto>;
export const TransactionListItemDto = z
	.object({
		...BaseTransactionFields,
		attachmentCount: z.int().nonnegative(),
	})
	.openapi("TransactionListItemDto");
export type TransactionListItemDto = z.infer<typeof TransactionListItemDto>;
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
export const PreviewItemsRequest = z
	.object({
		items: ItemsSplitInput.shape.items,
		extras: ItemsSplitInput.shape.extras,
		// The printed receipt total; when sent, the response carries the extra that would reach it.
		targetTotal: NonnegativeMoneyAmount.optional(),
	})
	.openapi("PreviewItemsRequest");
export type PreviewItemsRequest = z.infer<typeof PreviewItemsRequest>;
export const ItemsPreviewIssue = z.object({
	code: z.enum(["ITEM_UNASSIGNED", "INVALID_TOTAL"]),
	itemIndex: z.int().nonnegative().optional(),
});
export type ItemsPreviewIssue = z.infer<typeof ItemsPreviewIssue>;
export const PreviewItemsResponse = z
	.object({
		computedAmount: z.int(),
		shares: z.array(ShareDto).optional(),
		issues: z.array(ItemsPreviewIssue),
		targetAdjustment: z
			.object({
				kind: z.enum(["other", "discount"]),
				amount: z.int().positive(),
			})
			.nullable()
			.optional(),
	})
	.openapi("PreviewItemsResponse");
export type PreviewItemsResponse = z.infer<typeof PreviewItemsResponse>;
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
		transactions: z.array(TransactionListItemDto),
		nextCursor: z.string().nullable(),
	})
	.openapi("TransactionsResponse");

export const UpdateTransactionRequest = z.intersection(
	CreateTransactionRequest,
	z.object({ version: z.int().positive() }),
);
export type UpdateTransactionRequest = z.infer<typeof UpdateTransactionRequest>;
