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

export const EmailAddress = z
	.email()
	.max(254)
	.transform((email) => email.toLowerCase());
export const RegisterRequest = z
	.object({
		email: EmailAddress,
		name: z.string().trim().min(1).max(50),
		password: z.string().min(1).max(1024),
	})
	.openapi("RegisterRequest");
export type RegisterRequest = z.infer<typeof RegisterRequest>;
export const LoginRequest = z
	.object({ email: EmailAddress, password: z.string().min(1).max(1024) })
	.openapi("LoginRequest");
export type LoginRequest = z.infer<typeof LoginRequest>;
export const VerifyEmailRequest = z
	.object({ token: z.string().min(1).max(256) })
	.openapi("VerifyEmailRequest");
export const ProvidersResponse = z
	.object({ google: z.boolean(), devLogin: z.boolean() })
	.openapi("ProvidersResponse");

export const ForgotPasswordRequest = z
	.object({ email: EmailAddress })
	.openapi("ForgotPasswordRequest");
export type ForgotPasswordRequest = z.infer<typeof ForgotPasswordRequest>;
export const ResetPasswordRequest = z
	.object({
		token: z.string().min(1).max(256),
		password: z.string().min(1).max(1024),
	})
	.openapi("ResetPasswordRequest");
export type ResetPasswordRequest = z.infer<typeof ResetPasswordRequest>;
export const ChangePasswordRequest = z
	.object({
		currentPassword: z.string().min(1).max(1024),
		newPassword: z.string().min(1).max(1024),
		revokeOtherSessions: z.boolean(),
	})
	.openapi("ChangePasswordRequest");
export type ChangePasswordRequest = z.infer<typeof ChangePasswordRequest>;
export const DeleteAccountRequest = z
	.object({ email: EmailAddress })
	.openapi("DeleteAccountRequest");
export type DeleteAccountRequest = z.infer<typeof DeleteAccountRequest>;
