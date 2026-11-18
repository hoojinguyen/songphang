import { z } from "@hono/zod-openapi";
import { MoneyAmount, TransactionCategory } from "./transaction.ts";

export const RequestMemberRef = z.string().trim().min(1).max(64);
export type RequestMemberRef = z.infer<typeof RequestMemberRef>;

export const AiEqualSplitInput = z.object({
	method: z.literal("equal"),
	members: z.array(RequestMemberRef).min(1).max(100),
});

export const AiExactSplitInput = z.object({
	method: z.literal("exact"),
	members: z.array(RequestMemberRef).min(1).max(100),
	entries: z
		.array(
			z.object({
				memberId: RequestMemberRef,
				amount: MoneyAmount,
			}),
		)
		.max(100),
	remainder: z.enum(["none", "equal_among_blank", "equal_among_all"]),
});

export const AiSharesSplitInput = z.object({
	method: z.literal("shares"),
	entries: z
		.array(
			z.object({
				memberId: RequestMemberRef,
				weight: z.string().regex(/^\d{1,4}(\.\d{1,2})?$/),
			}),
		)
		.min(1)
		.max(100),
});

export const AiPercentSplitInput = z.object({
	method: z.literal("percent"),
	entries: z
		.array(
			z.object({
				memberId: RequestMemberRef,
				percent: z.string().regex(/^\d{1,3}(\.\d{1,2})?$/),
			}),
		)
		.min(1)
		.max(100),
});

export const AiSplitInput = z.discriminatedUnion("method", [
	AiEqualSplitInput,
	AiExactSplitInput,
	AiSharesSplitInput,
	AiPercentSplitInput,
]);
export type AiSplitInput = z.infer<typeof AiSplitInput>;

export const AiSentenceDraft = z.object({
	description: z.string().trim().min(1).max(200),
	amount: MoneyAmount,
	payerRef: RequestMemberRef.nullable(),
	split: AiSplitInput,
	category: TransactionCategory.nullable(),
	confident: z.boolean(),
});
export type AiSentenceDraft = z.infer<typeof AiSentenceDraft>;

export const SentenceAiAnswer = z.object({
	drafts: z.array(AiSentenceDraft).max(5),
});
export type SentenceAiAnswer = z.infer<typeof SentenceAiAnswer>;
