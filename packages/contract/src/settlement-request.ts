import { z } from "@hono/zod-openapi";
import { AttachmentDto } from "./attachment.ts";
import { PaymentChannel } from "./payment.ts";
import { MoneyAmount, TransactionDto } from "./transaction.ts";
export const SettlementStatus = z.enum([
	"pending",
	"confirmed",
	"rejected",
	"cancelled",
]);
export const SettlementRequestDto = z
	.object({
		id: z.uuid(),
		fromMemberId: z.uuid(),
		toMemberId: z.uuid(),
		amount: MoneyAmount,
		status: SettlementStatus,
		channel: PaymentChannel.nullable().optional(),
		note: z.string().nullable().optional(),
		proofAttachment: z.union([AttachmentDto, z.null()]).optional(),
		transactionId: z.uuid().nullable(),
		createdBy: z.object({ id: z.uuid(), name: z.string().max(80) }).nullable(),
		resolvedBy: z
			.object({ id: z.uuid(), name: z.string().max(80) })
			.nullable()
			.optional(),
		createdAt: z.iso.datetime(),
		resolvedAt: z.iso.datetime().nullable(),
	})
	.openapi("SettlementRequestDto");
export const SettlementRequestResponse = z.object({
	request: SettlementRequestDto,
});
export const ConfirmSettlementResponse = SettlementRequestResponse.extend({
	transaction: TransactionDto,
});
export const SettlementRequestsResponse = z.object({
	requests: z.array(SettlementRequestDto),
	nextCursor: z.uuid().nullable(),
});
export const SettlementRequestsQuery = z.object({
	status: SettlementStatus.optional(),
	cursor: z.uuid().optional(),
	limit: z.coerce.number().int().min(1).max(100).default(50),
});
export const CreateSettlementRequest = z
	.object({
		fromMemberId: z.uuid(),
		toMemberId: z.uuid(),
		amount: MoneyAmount,
		channel: PaymentChannel.optional(),
		note: z.string().trim().min(1).max(120).optional(),
		proofAttachmentId: z.uuid().optional(),
	})
	.refine((input) => input.fromMemberId !== input.toMemberId);
export type CreateSettlementRequest = z.infer<typeof CreateSettlementRequest>;
