import { z } from "@hono/zod-openapi";
import { AttachmentDto } from "./attachment.ts";
import { BalancesResponse, PayTo } from "./balance.ts";
import { FundSummary } from "./fund.ts";
import { GroupName } from "./group.ts";
import {
	AnyMemberColorCode,
	AnyMemberShapeCode,
	MemberColorCode,
	MemberKind,
	MemberName,
} from "./member.ts";
import {
	MemberBreakdownsResolvedFocus,
	MemberDebtBreakdownDto,
} from "./member-breakdown.ts";
import { PaymentChannel } from "./payment.ts";
import {
	CurrentPeriodSummaryDto,
	SettlementCycleDto,
} from "./settlement-cycle.ts";
import {
	MoneyAmount,
	ShareDto,
	SplitInput,
	TransactionCategory,
} from "./transaction.ts";

export const GuestToken = z
	.string()
	.min(32)
	.max(64)
	.regex(/^[A-Za-z0-9_-]+$/);
export type GuestToken = z.infer<typeof GuestToken>;

export const GuestLinkDto = z
	.object({
		active: z.boolean(),
		url: z.url().nullable(),
		createdAt: z.iso.datetime().nullable(),
	})
	.openapi("GuestLinkDto");
export type GuestLinkDto = z.infer<typeof GuestLinkDto>;

export const GuestLinkResponse = z
	.object({
		guestLink: GuestLinkDto,
	})
	.openapi("GuestLinkResponse");
export type GuestLinkResponse = z.infer<typeof GuestLinkResponse>;

export const CreateGuestLinkRequest = z
	.object({
		rotate: z.boolean().optional(),
	})
	.openapi("CreateGuestLinkRequest");
export type CreateGuestLinkRequest = z.infer<typeof CreateGuestLinkRequest>;

export const GuestGroupViewQuery = z.object({
	cycleId: z.union([z.literal("current"), z.uuid()]).optional(),
	cursor: z.string().max(512).optional(),
	limit: z.coerce.number().int().min(1).max(100).default(50),
});
export type GuestGroupViewQuery = z.infer<typeof GuestGroupViewQuery>;

export const GuestMemberDto = z
	.object({
		id: z.uuid(),
		name: MemberName,
		kind: MemberKind,
		active: z.boolean(),
		shape: AnyMemberShapeCode,
		color: AnyMemberColorCode,
	})
	.openapi("GuestMemberDto");
export type GuestMemberDto = z.infer<typeof GuestMemberDto>;

export const GuestTransactionDto = z
	.object({
		id: z.uuid(),
		type: z.enum(["expense", "income", "transfer"]),
		description: z.string(),
		amount: MoneyAmount,
		currency: z.literal("VND"),
		occurredAt: z.iso.datetime(),
		category: TransactionCategory.nullable(),
		categoryId: z.uuid().nullable(),
		categoryName: z.string().nullable().optional(),
		categoryColor: MemberColorCode.nullable().optional(),
		payers: z.array(z.object({ memberId: z.uuid(), amount: MoneyAmount })),
		shares: z.array(ShareDto),
		split: SplitInput,
		paymentChannel: PaymentChannel.nullable().optional(),
		paymentNote: z.string().nullable().optional(),
		cycleId: z.uuid().nullable(),
		attachments: z.array(AttachmentDto).max(3),
	})
	.refine((tx) => tx.type !== "transfer" || tx.attachments.length === 0, {
		message: "Transfer rows in guest view must not expose attachments",
		path: ["attachments"],
	})
	.openapi("GuestTransactionDto");
export type GuestTransactionDto = z.infer<typeof GuestTransactionDto>;

export const GuestGroupViewResponse = z
	.object({
		group: z.object({
			id: z.uuid(),
			name: GroupName,
			currency: z.literal("VND"),
			minimized: z.boolean(),
			archivedAt: z.iso.datetime().nullable(),
		}),
		members: z.array(GuestMemberDto),
		cycles: z.array(SettlementCycleDto),
		selectedCycleId: z.union([z.literal("current"), z.uuid()]),
		currentPeriod: CurrentPeriodSummaryDto,
		balances: BalancesResponse.shape.balances,
		transfers: z.array(
			z.object({
				fromMemberId: z.uuid(),
				toMemberId: z.uuid(),
				amount: MoneyAmount,
				purpose: z.string().min(1).max(25),
				payTo: z.array(PayTo).max(3),
			}),
		),
		fund: FundSummary.nullable().default(null),
		resolvedFocus: MemberBreakdownsResolvedFocus,
		breakdowns: z.array(MemberDebtBreakdownDto),
		transactions: z.object({
			items: z.array(GuestTransactionDto),
			nextCursor: z.string().nullable(),
		}),
	})
	.openapi("GuestGroupViewResponse");
export type GuestGroupViewResponse = z.infer<typeof GuestGroupViewResponse>;
