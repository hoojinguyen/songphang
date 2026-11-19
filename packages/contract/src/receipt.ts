import { z } from "@hono/zod-openapi";
import { CalendarDate } from "./transaction.ts";

export const ReceiptMoney = z.int().min(0).max(999_999_999_999);

export const ReceiptItem = z.object({
	name: z.string().trim().min(1).max(80),
	quantity: z.int().min(1).max(999),
	amount: ReceiptMoney,
});
export type ReceiptItem = z.infer<typeof ReceiptItem>;

export const ReceiptExtraKind = z.enum(["tax", "service", "discount", "other"]);
export type ReceiptExtraKind = z.infer<typeof ReceiptExtraKind>;

export const ReceiptExtra = z.object({
	kind: ReceiptExtraKind,
	label: z.string().trim().max(40),
	amount: ReceiptMoney,
});
export type ReceiptExtra = z.infer<typeof ReceiptExtra>;

export const ReceiptReading = z
	.object({
		merchant: z
			.string()
			.trim()
			.max(80)
			.transform((value) => (value.length === 0 ? null : value))
			.nullable(),
		occurredOn: CalendarDate.nullable(),
		items: z.array(ReceiptItem).max(60),
		extras: z.array(ReceiptExtra).max(6),
		total: ReceiptMoney.nullable(),
	})
	.openapi("ReceiptReading");
export type ReceiptReading = z.infer<typeof ReceiptReading>;

export const ReceiptFlag = z.enum([
	"TOTAL_MISMATCH",
	"TOTAL_MISSING",
	"NO_ITEMS",
]);
export type ReceiptFlag = z.infer<typeof ReceiptFlag>;

export const ReceiptScanStatus = z.enum([
	"queued",
	"processing",
	"done",
	"failed",
]);
export type ReceiptScanStatus = z.infer<typeof ReceiptScanStatus>;

export const ReceiptScanDto = z
	.object({
		id: z.uuid(),
		attachmentId: z.uuid(),
		status: ReceiptScanStatus,
		reading: ReceiptReading.nullable(),
		computed: z.int().nullable(),
		flags: z.array(ReceiptFlag),
		errorCode: z.string().nullable(),
		createdAt: z.iso.datetime(),
	})
	.openapi("ReceiptScanDto");
export type ReceiptScanDto = z.infer<typeof ReceiptScanDto>;

export const ReceiptScanResponse = z
	.object({ scan: ReceiptScanDto })
	.openapi("ReceiptScanResponse");
export type ReceiptScanResponse = z.infer<typeof ReceiptScanResponse>;

export const CreateReceiptScanRequest = z
	.object({ attachmentId: z.uuid() })
	.openapi("CreateReceiptScanRequest");
export type CreateReceiptScanRequest = z.infer<typeof CreateReceiptScanRequest>;
