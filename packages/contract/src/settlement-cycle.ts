import { z } from "@hono/zod-openapi";
import { MemberColorCode, MemberName, MemberShapeCode } from "./member.ts";
import { MoneyAmount } from "./transaction.ts";

export const SettlementCycleBalanceSnapshot = z.object({
	memberId: z.uuid(),
	name: MemberName,
	shape: MemberShapeCode,
	color: MemberColorCode,
	balance: z.int(),
});
export type SettlementCycleBalanceSnapshot = z.infer<
	typeof SettlementCycleBalanceSnapshot
>;

export const SettlementCycleTransferSnapshot = z.object({
	fromMemberId: z.uuid(),
	fromName: MemberName,
	toMemberId: z.uuid(),
	toName: MemberName,
	amount: MoneyAmount,
});
export type SettlementCycleTransferSnapshot = z.infer<
	typeof SettlementCycleTransferSnapshot
>;

export const SettlementCycleSnapshot = z
	.object({
		balances: z.array(SettlementCycleBalanceSnapshot),
		transfers: z.array(SettlementCycleTransferSnapshot),
		fundBalance: z.int().nullable(),
	})
	.openapi("SettlementCycleSnapshot");
export type SettlementCycleSnapshot = z.infer<typeof SettlementCycleSnapshot>;

export const SettlementCycleDto = z
	.object({
		id: z.uuid(),
		cycleNumber: z.int().min(1),
		title: z.string().min(1).max(80),
		startedAt: z.iso.datetime(),
		closedAt: z.iso.datetime(),
		closedBy: z.object({ id: z.uuid(), name: z.string() }).nullable(),
		expenseCount: z.int().nonnegative(),
		totalExpenseAmount: z.int().nonnegative(),
		snapshot: SettlementCycleSnapshot,
	})
	.openapi("SettlementCycleDto");
export type SettlementCycleDto = z.infer<typeof SettlementCycleDto>;

export const CurrentPeriodSummaryDto = z
	.object({
		startedAt: z.iso.datetime(),
		expenseCount: z.int().nonnegative(),
		totalExpenseAmount: z.int().nonnegative(),
		countedTransactionCount: z.int().nonnegative(),
	})
	.openapi("CurrentPeriodSummaryDto");
export type CurrentPeriodSummaryDto = z.infer<typeof CurrentPeriodSummaryDto>;

export const SettlementCyclesResponse = z
	.object({
		cycles: z.array(SettlementCycleDto),
		currentPeriod: CurrentPeriodSummaryDto,
	})
	.openapi("SettlementCyclesResponse");
export type SettlementCyclesResponse = z.infer<typeof SettlementCyclesResponse>;

export const CreateSettlementCycleRequest = z
	.object({
		title: z.string().trim().min(1).max(80).optional(),
	})
	.openapi("CreateSettlementCycleRequest");
export type CreateSettlementCycleRequest = z.infer<
	typeof CreateSettlementCycleRequest
>;

export const SettlementCycleResponse = z
	.object({
		cycle: SettlementCycleDto,
	})
	.openapi("SettlementCycleResponse");
export type SettlementCycleResponse = z.infer<typeof SettlementCycleResponse>;
