import { z } from "@hono/zod-openapi";
import { MemberName } from "./member.ts";

export const CreateFundRequest = z
	.object({
		name: MemberName.optional(),
		holderMemberId: z.uuid().optional(),
	})
	.openapi("CreateFundRequest");
export type CreateFundRequest = z.infer<typeof CreateFundRequest>;

export const UpdateFundRequest = z
	.object({
		name: MemberName.optional(),
		holderMemberId: z.uuid().nullable().optional(),
		active: z.boolean().optional(),
	})
	.refine((request) => Object.keys(request).length > 0)
	.openapi("UpdateFundRequest");
export type UpdateFundRequest = z.infer<typeof UpdateFundRequest>;

export const FundContribution = z.object({
	memberId: z.uuid(),
	amount: z.int(),
});

export const FundSummary = z
	.object({
		memberId: z.uuid(),
		name: MemberName,
		active: z.boolean(),
		cash: z.int(),
		holderMemberId: z.uuid().nullable(),
		contributions: z.array(FundContribution),
	})
	.openapi("FundSummary");
export type FundSummary = z.infer<typeof FundSummary>;
