import { z } from "@hono/zod-openapi";
import { MemberColorCode, MemberName, MemberShapeCode } from "./member.js";
export const GroupName = z.string().trim().min(1).max(80);
export const GroupRole = z.enum(["owner", "editor", "viewer"]);
export type GroupRole = z.infer<typeof GroupRole>;
export const GroupDto = z
	.object({
		id: z.uuid(),
		name: GroupName,
		currency: z.literal("VND"),
		minimizeDebts: z.boolean(),
		role: GroupRole,
		myMemberId: z.uuid().nullable(),
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
	.object({ name: GroupName.optional(), minimizeDebts: z.boolean().optional() })
	.refine((value) => Object.keys(value).length > 0)
	.openapi("UpdateGroupRequest");
export type UpdateGroupRequest = z.infer<typeof UpdateGroupRequest>;
export const IdempotencyKeyHeader = z
	.string()
	.min(8)
	.max(128)
	.regex(/^[A-Za-z0-9_-]+$/);
