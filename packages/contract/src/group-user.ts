import { z } from "@hono/zod-openapi";
import { GroupRole } from "./group.ts";
export const GroupUserDto = z
	.object({
		userId: z.uuid(),
		name: z.string(),
		role: GroupRole,
		memberId: z.uuid().nullable(),
		isMe: z.boolean(),
	})
	.openapi("GroupUserDto");
export type GroupUserDto = z.infer<typeof GroupUserDto>;
export const GroupUsersResponse = z
	.object({ users: z.array(GroupUserDto) })
	.openapi("GroupUsersResponse");
export const UpdateGroupUserRequest = z
	.object({ role: z.enum(["editor", "viewer"]) })
	.openapi("UpdateGroupUserRequest");
export type UpdateGroupUserRequest = z.infer<typeof UpdateGroupUserRequest>;
export const TransferOwnershipRequest = z
	.object({ userId: z.uuid() })
	.openapi("TransferOwnershipRequest");
export type TransferOwnershipRequest = z.infer<typeof TransferOwnershipRequest>;
