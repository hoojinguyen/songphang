import { z } from "@hono/zod-openapi";
import { MoneyAmount, ShareDto, SplitInput } from "./transaction.ts";
export const ParseRequest = z.object({ text: z.string().min(1).max(300) });
export type ParseRequest = z.infer<typeof ParseRequest>;
export const ParseDraft = z.object({
	type: z.literal("expense"),
	description: z.string().nullable(),
	amount: MoneyAmount.nullable(),
	payers: z.array(z.object({ memberId: z.uuid(), amount: MoneyAmount })).max(1),
	split: SplitInput.nullable(),
});
export type ParseDraft = z.infer<typeof ParseDraft>;
export const ParseIssue = z.object({
	code: z.enum([
		"AMOUNT_MISSING",
		"DESCRIPTION_MISSING",
		"MEMBER_AMBIGUOUS",
		"MEMBER_UNKNOWN",
		"COUNT_MISMATCH",
		"SUM_MISMATCH",
		"TEXT_NOT_UNDERSTOOD",
	]),
	start: z.int().nonnegative(),
	end: z.int().nonnegative(),
	candidates: z.array(z.uuid()),
	count: z.number().optional(),
	expected: z.number().optional(),
	actual: z.number().optional(),
});
export const ParseSpan = z.object({
	start: z.int().nonnegative(),
	end: z.int().nonnegative(),
	kind: z.enum([
		"amount",
		"description",
		"payer",
		"equal",
		"exact",
		"remainder",
	]),
});
export const ParseResponse = z
	.object({
		status: z.enum(["ok", "needs_input", "unparsed"]),
		text: z.string(),
		draft: ParseDraft,
		shares: z.array(ShareDto).optional(),
		spans: z.array(ParseSpan),
		issues: z.array(ParseIssue),
	})
	.openapi("ParseResponse");
export type ParseResponse = z.infer<typeof ParseResponse>;
