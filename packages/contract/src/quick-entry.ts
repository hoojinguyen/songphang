import { z } from "@hono/zod-openapi";
import {
	MoneyAmount,
	ShareDto,
	SplitInput,
	TransactionCategory,
} from "./transaction.ts";

// The AI reader runs only when the user explicitly sends, never on the debounced live reading.
export const ParseRequest = z.object({
	text: z.string().min(1).max(300),
	ai: z.boolean().default(false),
});
export type ParseRequest = z.infer<typeof ParseRequest>;

export const ParseDraft = z
	.object({
		type: z.literal("expense"),
		description: z.string().nullable(),
		amount: MoneyAmount.nullable(),
		payers: z
			.array(z.object({ memberId: z.uuid(), amount: MoneyAmount }))
			.max(1),
		split: SplitInput.nullable(),
		category: TransactionCategory.nullable().default(null),
		categoryId: z.uuid().nullable().default(null),
	})
	.refine((draft) => !(draft.category !== null && draft.categoryId !== null), {
		message: "category and categoryId are mutually exclusive",
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
		"FUND_CANNOT_SHARE",
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

export const ParsedDraftResult = z.object({
	status: z.enum(["ok", "needs_input", "unparsed"]),
	draft: ParseDraft,
	issues: z.array(ParseIssue),
	shares: z.array(ShareDto).optional(),
});
export type ParsedDraftResult = z.infer<typeof ParsedDraftResult>;

export const ParseResponse = z
	.object({
		status: z.enum(["ok", "needs_input", "unparsed"]),
		text: z.string(),
		draft: ParseDraft,
		shares: z.array(ShareDto).optional(),
		spans: z.array(ParseSpan),
		issues: z.array(ParseIssue),
		reader: z.enum(["rules", "ai"]).default("rules"),
		moreDrafts: z.array(ParsedDraftResult).max(4).default([]),
	})
	.openapi("ParseResponse");
export type ParseResponse = z.infer<typeof ParseResponse>;
