import { z } from "@hono/zod-openapi";
import { BANKS, findBank } from "@songphang/core";

export { BANKS };

export const PaymentChannel = z
	.enum(["bank", "momo", "zalopay", "cash"])
	.openapi("PaymentChannel");
export type PaymentChannel = z.infer<typeof PaymentChannel>;

const BankBin = z
	.string()
	.regex(/^\d{6}$/)
	.refine((value) => findBank(value) !== undefined);
const AccountNumber = z.string().regex(/^[A-Za-z0-9]{4,19}$/);
const AccountName = z.string().trim().min(1).max(50);
const Phone = z
	.string()
	.min(1)
	.max(32)
	.transform((value) => {
		const compact = value.replace(/[ .]/g, "");
		return compact.replace(/^\+?84/, "0");
	})
	.pipe(z.string().regex(/^0\d{9}$/));
export const PaymentMethodInput = z.discriminatedUnion("kind", [
	z.object({
		kind: z.literal("bank"),
		bankBin: BankBin,
		accountNumber: AccountNumber,
		accountName: AccountName,
	}),
	z.object({ kind: z.literal("momo"), phone: Phone }),
	z.object({ kind: z.literal("zalopay"), phone: Phone }),
]);
export type PaymentMethodInput = z.infer<typeof PaymentMethodInput>;
export const PaymentMethodDto = z.discriminatedUnion("kind", [
	z.object({
		kind: z.literal("bank"),
		bankBin: BankBin,
		bankShortName: z.string().min(1).max(100),
		accountNumber: AccountNumber,
		accountName: AccountName,
	}),
	z.object({ kind: z.literal("momo"), phone: z.string().regex(/^0\d{9}$/) }),
	z.object({ kind: z.literal("zalopay"), phone: z.string().regex(/^0\d{9}$/) }),
]);
export type PaymentMethodDto = z.infer<typeof PaymentMethodDto>;
export const ReplacePaymentMethodsRequest = z.object({
	methods: z
		.array(PaymentMethodInput)
		.max(3)
		.refine(
			(methods) =>
				new Set(methods.map((method) => method.kind)).size === methods.length,
		),
});
