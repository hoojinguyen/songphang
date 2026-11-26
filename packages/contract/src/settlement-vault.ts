import { z } from "@hono/zod-openapi";
import { AttachmentDto } from "./attachment.ts";
import { PaymentChannel } from "./payment.ts";
import { SettlementStatus } from "./settlement-request.ts";
import { MoneyAmount } from "./transaction.ts";

export const SettlementVaultFilter = z
	.enum(["all", "pending", "confirmed", "with_proof"])
	.openapi("SettlementVaultFilter");
export type SettlementVaultFilter = z.infer<typeof SettlementVaultFilter>;

export const SettlementVaultQuery = z.object({
	filter: SettlementVaultFilter.default("all"),
	cycleId: z.union([z.literal("current"), z.uuid()]).optional(),
	cursor: z.string().max(512).optional(),
	limit: z.coerce.number().int().min(1).max(100).default(50),
});
export type SettlementVaultQuery = z.infer<typeof SettlementVaultQuery>;

export const SettlementVaultItemDto = z
	.object({
		id: z.uuid(),
		kind: z.enum(["transfer", "request"]),
		status: SettlementStatus,
		transactionId: z.uuid().nullable(),
		settlementRequestId: z.uuid().nullable(),
		fromMemberId: z.uuid(),
		toMemberId: z.uuid(),
		amount: MoneyAmount,
		channel: PaymentChannel.nullable(),
		note: z.string().nullable(),
		description: z.string().nullable(),
		attachments: z.array(AttachmentDto).max(3),
		createdBy: z.object({ id: z.uuid(), name: z.string() }).nullable(),
		resolvedBy: z.object({ id: z.uuid(), name: z.string() }).nullable(),
		occurredAt: z.iso.datetime(),
		resolvedAt: z.iso.datetime().nullable(),
		cycleId: z.uuid().nullable(),
	})
	.openapi("SettlementVaultItemDto");
export type SettlementVaultItemDto = z.infer<typeof SettlementVaultItemDto>;

export const SettlementVaultSummaryDto = z
	.object({
		pendingCount: z.int().nonnegative(),
		confirmedCount: z.int().nonnegative(),
		confirmedTotalAmount: z.int().nonnegative(),
		proofCount: z.int().nonnegative(),
	})
	.openapi("SettlementVaultSummaryDto");
export type SettlementVaultSummaryDto = z.infer<
	typeof SettlementVaultSummaryDto
>;

export const SettlementVaultResponse = z
	.object({
		items: z.array(SettlementVaultItemDto),
		summary: SettlementVaultSummaryDto,
		nextCursor: z.string().nullable(),
	})
	.openapi("SettlementVaultResponse");
export type SettlementVaultResponse = z.infer<typeof SettlementVaultResponse>;
