import { z } from "@hono/zod-openapi";
import { HouseholdName } from "./household.ts";
import { MemberColorCode, MemberName, MemberShapeCode } from "./member.ts";
import { MoneyAmount } from "./transaction.ts";

export const MemberBreakdownsQuery = z.object({
	cycleId: z
		.union([z.literal("auto"), z.literal("current"), z.uuid()])
		.default("auto"),
});
export type MemberBreakdownsQuery = z.infer<typeof MemberBreakdownsQuery>;

export const MemberBreakdownLineDto = z
	.object({
		transactionId: z.uuid(),
		type: z.enum(["expense", "income", "transfer"]),
		description: z.string(),
		occurredAt: z.iso.datetime(),
		totalAmount: MoneyAmount,
		payerSummary: z.string(),
		memberPaid: z.int().nonnegative(),
		memberShare: z.int().nonnegative(),
		delta: z.int(),
		isPostCloseoutTransfer: z.boolean(),
	})
	.openapi("MemberBreakdownLineDto");
export type MemberBreakdownLineDto = z.infer<typeof MemberBreakdownLineDto>;

export const MemberDebtBreakdownDto = z
	.object({
		memberId: z.uuid(),
		memberName: MemberName,
		shape: MemberShapeCode,
		color: MemberColorCode,
		carryOverBalance: z.int(),
		focusExpenseDelta: z.int(),
		focusTransferDelta: z.int(),
		postCycleDelta: z.int(),
		netBalance: z.int(),
		lines: z.array(MemberBreakdownLineDto),
	})
	.openapi("MemberDebtBreakdownDto");
export type MemberDebtBreakdownDto = z.infer<typeof MemberDebtBreakdownDto>;

export const MemberBreakdownsResolvedFocus = z
	.object({
		kind: z.enum(["all", "current", "cycle"]),
		cycleId: z.uuid().nullable(),
		label: z.string(),
	})
	.openapi("MemberBreakdownsResolvedFocus");
export type MemberBreakdownsResolvedFocus = z.infer<
	typeof MemberBreakdownsResolvedFocus
>;

export const HouseholdDebtBreakdownDto = z
	.object({
		householdId: z.uuid(),
		name: HouseholdName,
		representativeMemberId: z.uuid(),
		memberIds: z.array(z.uuid()),
		carryOverBalance: z.int(),
		focusExpenseDelta: z.int(),
		focusTransferDelta: z.int(),
		postCycleDelta: z.int(),
		netBalance: z.int(),
	})
	.openapi("HouseholdDebtBreakdownDto");
export type HouseholdDebtBreakdownDto = z.infer<
	typeof HouseholdDebtBreakdownDto
>;

export const MemberBreakdownsResponse = z
	.object({
		hasClosedCycles: z.boolean(),
		resolvedFocus: MemberBreakdownsResolvedFocus,
		breakdowns: z.array(MemberDebtBreakdownDto),
		householdBreakdowns: z.array(HouseholdDebtBreakdownDto).optional(),
	})
	.openapi("MemberBreakdownsResponse");
export type MemberBreakdownsResponse = z.infer<typeof MemberBreakdownsResponse>;
