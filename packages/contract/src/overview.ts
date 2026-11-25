import { z } from "@hono/zod-openapi";
import { GroupName, GroupRole } from "./group.ts";
import { MemberColorCode, MemberName, MemberShapeCode } from "./member.ts";
import {
	ApprovalStatus,
	MoneyAmount,
	TransactionCategory,
} from "./transaction.ts";

export const OverviewSettlementAction = z
	.object({
		kind: z.literal("settlement_confirmation"),
		id: z.uuid(),
		groupId: z.uuid(),
		groupName: GroupName,
		amount: MoneyAmount,
		actorName: z.string(),
		description: z.string(),
		createdAt: z.iso.datetime(),
	})
	.openapi("OverviewSettlementAction");
export type OverviewSettlementAction = z.infer<typeof OverviewSettlementAction>;

export const OverviewApprovalAction = z
	.object({
		kind: z.literal("expense_approval"),
		id: z.uuid(),
		groupId: z.uuid(),
		groupName: GroupName,
		amount: MoneyAmount,
		actorName: z.string(),
		description: z.string(),
		createdAt: z.iso.datetime(),
	})
	.openapi("OverviewApprovalAction");
export type OverviewApprovalAction = z.infer<typeof OverviewApprovalAction>;

export const OverviewPendingAction = z
	.discriminatedUnion("kind", [
		OverviewSettlementAction,
		OverviewApprovalAction,
	])
	.openapi("OverviewPendingAction");
export type OverviewPendingAction = z.infer<typeof OverviewPendingAction>;

export const OverviewGroupBalance = z
	.object({
		groupId: z.uuid(),
		groupName: GroupName,
		archivedAt: z.iso.datetime().nullable(),
		role: GroupRole,
		myBalance: z.int(),
		memberCount: z.int().nonnegative(),
		previewMembers: z
			.array(
				z.object({
					id: z.uuid(),
					name: MemberName,
					shape: MemberShapeCode,
					color: MemberColorCode,
				}),
			)
			.max(4),
	})
	.openapi("OverviewGroupBalance");
export type OverviewGroupBalance = z.infer<typeof OverviewGroupBalance>;

export const OverviewResponse = z
	.object({
		totalOwedToMe: z.int().nonnegative(),
		totalIOwe: z.int().nonnegative(),
		netBalance: z.int(),
		activeGroupCount: z.int().nonnegative(),
		archivedGroupCount: z.int().nonnegative(),
		pendingSettlementCount: z.int().nonnegative(),
		pendingApprovalCount: z.int().nonnegative(),
		pendingActions: z.array(OverviewPendingAction).max(20),
		groupBalances: z.array(OverviewGroupBalance),
	})
	.openapi("OverviewResponse");
export type OverviewResponse = z.infer<typeof OverviewResponse>;

export const PersonalTransactionsQuery = z.object({
	cursor: z.string().max(512).optional(),
	limit: z.coerce.number().int().min(1).max(50).default(20),
	type: z.enum(["expense", "transfer", "income"]).optional(),
	groupId: z.uuid().optional(),
	q: z.string().trim().min(1).max(100).optional(),
});
export type PersonalTransactionsQuery = z.infer<
	typeof PersonalTransactionsQuery
>;

export const PersonalTransactionDto = z
	.object({
		id: z.uuid(),
		groupId: z.uuid(),
		groupName: GroupName,
		groupArchivedAt: z.iso.datetime().nullable(),
		type: z.enum(["expense", "income", "transfer"]),
		description: z.string(),
		amount: MoneyAmount,
		myDelta: z.int(),
		occurredAt: z.iso.datetime(),
		category: TransactionCategory.nullable(),
		categoryName: z.string().nullable(),
		payerSummary: z.string(),
		participantCount: z.int().nonnegative(),
		approvalStatus: ApprovalStatus,
		hasOpenDispute: z.boolean(),
	})
	.openapi("PersonalTransactionDto");
export type PersonalTransactionDto = z.infer<typeof PersonalTransactionDto>;

export const PersonalTransactionsResponse = z
	.object({
		items: z.array(PersonalTransactionDto),
		nextCursor: z.string().nullable(),
	})
	.openapi("PersonalTransactionsResponse");
export type PersonalTransactionsResponse = z.infer<
	typeof PersonalTransactionsResponse
>;
