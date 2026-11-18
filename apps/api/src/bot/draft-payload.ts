import { z } from "@hono/zod-openapi";
import {
	MoneyAmount,
	SplitInput,
	TransactionCategory,
} from "@songphang/contract";

export const BotDraftPayload = z.object({
	description: z.string().trim().min(1).max(200),
	amount: MoneyAmount,
	category: TransactionCategory.nullable(),
	categoryId: z.uuid().nullable(),
	payers: z.array(z.object({ memberId: z.uuid(), amount: MoneyAmount })).min(1),
	split: SplitInput,
});
export type BotDraftPayload = z.infer<typeof BotDraftPayload>;
