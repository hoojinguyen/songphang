import { z } from "@hono/zod-openapi";
import { FundSummary } from "./fund.ts";
import { PaymentMethodDto } from "./payment.ts";
export const PayTo = z.discriminatedUnion("kind", [
	PaymentMethodDto.options[0].extend({ qrPayload: z.string().min(1).max(512) }),
	PaymentMethodDto.options[1],
	PaymentMethodDto.options[2],
]);
export const BalancesResponse = z
	.object({
		currency: z.literal("VND"),
		minimized: z.boolean(),
		balances: z.array(z.object({ memberId: z.uuid(), balance: z.int() })),
		transfers: z.array(
			z.object({
				fromMemberId: z.uuid(),
				toMemberId: z.uuid(),
				amount: z.int().positive(),
				payTo: z.array(PayTo).max(3),
				purpose: z.string().min(1).max(25),
				pendingRequest: z
					.object({
						id: z.uuid(),
						amount: z.int().positive(),
						createdByMe: z.boolean(),
					})
					.nullable(),
			}),
		),
		fund: FundSummary.nullable().default(null),
	})
	.openapi("BalancesResponse");
export type BalancesResponse = z.infer<typeof BalancesResponse>;
