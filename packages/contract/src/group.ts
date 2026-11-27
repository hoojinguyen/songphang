import { z } from "@hono/zod-openapi";
import { MemberColorCode, MemberName, MemberShapeCode } from "./member.ts";
import { MoneyAmount } from "./transaction.ts";
export const GroupName = z.string().trim().min(1).max(80);
export const GroupRole = z.enum(["owner", "editor", "viewer"]);
export type GroupRole = z.infer<typeof GroupRole>;
export const GroupStatusFilter = z.enum(["active", "archived", "all"]);
export type GroupStatusFilter = z.infer<typeof GroupStatusFilter>;
export const GroupsQuery = z.object({
	status: GroupStatusFilter.default("all"),
});
export type GroupsQuery = z.infer<typeof GroupsQuery>;
export const ReminderIntervalDays = z.union([
	z.literal(3),
	z.literal(7),
	z.literal(14),
]);
export type ReminderIntervalDays = z.infer<typeof ReminderIntervalDays>;
export const GroupDto = z
	.object({
		id: z.uuid(),
		name: GroupName,
		currency: z.literal("VND"),
		minimizeDebts: z.boolean(),
		defaultRole: z.enum(["editor", "viewer"]),
		reminderIntervalDays: ReminderIntervalDays.nullable(),
		approvalThreshold: MoneyAmount.nullable(),
		ownerName: z.string(),
		role: GroupRole,
		myMemberId: z.uuid().nullable(),
		muted: z.boolean(),
		archivedAt: z.iso.datetime().nullable().optional(),
		createdAt: z.iso.datetime(),
	})
	.openapi("GroupDto");
export type GroupDto = z.infer<typeof GroupDto>;
export const GroupSummaryDto = z
	.object({
		id: z.uuid(),
		name: GroupName,
		currency: z.literal("VND"),
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
		myBalance: z.int(),
		myIndividualBalance: z.int().optional(),
		householdName: z.string().nullable().optional(),
		archivedAt: z.iso.datetime().nullable().optional(),
		role: GroupRole.optional(),
		myMemberId: z.uuid().nullable().optional(),
		pendingActionCount: z.int().nonnegative().optional(),
	})
	.openapi("GroupSummaryDto");
export type GroupSummaryDto = z.infer<typeof GroupSummaryDto>;
export const GroupsResponse = z
	.object({ groups: z.array(GroupSummaryDto) })
	.openapi("GroupsResponse");
export const GroupResponse = z
	.object({ group: GroupDto })
	.openapi("GroupResponse");
export const CreateGroupRequest = z
	.object({
		name: GroupName,
		memberNames: z.array(MemberName).max(99).default([]),
	})
	.openapi("CreateGroupRequest");
export type CreateGroupRequest = z.infer<typeof CreateGroupRequest>;
export const UpdateGroupRequest = z
	.object({
		name: GroupName.optional(),
		minimizeDebts: z.boolean().optional(),
		defaultRole: z.enum(["editor", "viewer"]).optional(),
		reminderIntervalDays: ReminderIntervalDays.nullable().optional(),
		approvalThreshold: MoneyAmount.nullable().optional(),
	})
	.refine((value) => Object.keys(value).length > 0)
	.openapi("UpdateGroupRequest");
export type UpdateGroupRequest = z.infer<typeof UpdateGroupRequest>;
export const IdempotencyKeyHeader = z
	.string()
	.min(8)
	.max(128)
	.regex(/^[A-Za-z0-9_-]+$/);

export const DeleteGroupRequest = z.object({ name: z.string().min(1).max(80) });
export type DeleteGroupRequest = z.infer<typeof DeleteGroupRequest>;

export const CloneGroupRequest = z
	.object({
		name: GroupName,
		includeMembers: z.boolean().optional(),
		copyPaymentMethods: z.boolean().default(true),
		copyCategories: z.boolean().default(false),
	})
	.openapi("CloneGroupRequest");
export type CloneGroupRequest = z.infer<typeof CloneGroupRequest>;
