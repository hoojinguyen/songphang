import { z } from "@hono/zod-openapi";

export const UserDto = z
	.object({
		id: z.uuid(),
		email: z.string(),
		name: z.string(),
		avatarUrl: z.string().nullable(),
		emailVerified: z.boolean(),
		hasPassword: z.boolean(),
	})
	.openapi("UserDto");
export type UserDto = z.infer<typeof UserDto>;

export const MeResponse = z.object({ user: UserDto }).openapi("MeResponse");
export type MeResponse = z.infer<typeof MeResponse>;

export const DevUsersResponse = z
	.object({ users: z.array(UserDto) })
	.openapi("DevUsersResponse");
export type DevUsersResponse = z.infer<typeof DevUsersResponse>;

export const DevLoginRequest = z
	.object({ userId: z.uuid() })
	.openapi("DevLoginRequest");
export type DevLoginRequest = z.infer<typeof DevLoginRequest>;
