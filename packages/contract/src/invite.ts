import { z } from "@hono/zod-openapi";
import { MemberColorCode, MemberName, MemberShapeCode } from "./member.ts";
export const InviteToken = z
	.string()
	.min(1)
	.max(256)
	.regex(/^[A-Za-z0-9_-]+$/);
export const InviteDto = z
	.object({ token: z.string(), active: z.boolean(), url: z.url() })
	.openapi("InviteDto");
export type InviteDto = z.infer<typeof InviteDto>;
export const InviteResponse = z
	.object({ invite: InviteDto })
	.openapi("InviteResponse");
export const InvitePreviewResponse = z
	.object({
		group: z.object({ id: z.uuid(), name: z.string() }),
		ownerName: z.string(),
		memberCount: z.int().nonnegative(),
		transactionCount: z.int().nonnegative(),
		members: z.array(
			z.object({
				id: z.uuid(),
				name: MemberName,
				shape: MemberShapeCode,
				color: MemberColorCode,
				claimed: z.boolean(),
				balance: z.int().nullable(),
			}),
		),
		alreadyJoined: z.boolean(),
	})
	.openapi("InvitePreviewResponse");
export const JoinRequest = z
	.union([
		z.strictObject({ memberId: z.uuid() }),
		z.strictObject({ newMemberName: MemberName }),
	])
	.openapi("JoinRequest");
export type JoinRequest = z.infer<typeof JoinRequest>;
export const JoinResponse = z
	.object({ groupId: z.uuid() })
	.openapi("JoinResponse");
export const ChooseMemberRequest = z
	.object({ memberId: z.uuid() })
	.openapi("ChooseMemberRequest");
