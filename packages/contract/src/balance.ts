import { z } from "@hono/zod-openapi";
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
			}),
		),
	})
	.openapi("BalancesResponse");
export type BalancesResponse = z.infer<typeof BalancesResponse>;
