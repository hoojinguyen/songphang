import { z } from "@hono/zod-openapi";

export const PushPlatform = z.enum(["ios", "android"]).openapi("PushPlatform");
export type PushPlatform = z.infer<typeof PushPlatform>;

export const PushEnvironment = z
	.enum(["sandbox", "production"])
	.openapi("PushEnvironment");
export type PushEnvironment = z.infer<typeof PushEnvironment>;

export const PushDeviceToken = z
	.string()
	.min(16)
	.max(512)
	.regex(/^[A-Za-z0-9:_-]+$/)
	.openapi("PushDeviceToken");

export const RegisterDeviceRequest = z
	.object({
		platform: PushPlatform,
		token: PushDeviceToken,
		environment: PushEnvironment,
	})
	.openapi("RegisterDeviceRequest");
export type RegisterDeviceRequest = z.infer<typeof RegisterDeviceRequest>;

export const RegisterDeviceResponse = z
	.object({
		id: z.uuid(),
	})
	.openapi("RegisterDeviceResponse");
export type RegisterDeviceResponse = z.infer<typeof RegisterDeviceResponse>;

export const UpdatePushSettingsRequest = z
	.object({
		hideContent: z.boolean(),
	})
	.openapi("UpdatePushSettingsRequest");
export type UpdatePushSettingsRequest = z.infer<
	typeof UpdatePushSettingsRequest
>;

export const PushSettingsResponse = z
	.object({
		hideContent: z.boolean(),
	})
	.openapi("PushSettingsResponse");
export type PushSettingsResponse = z.infer<typeof PushSettingsResponse>;
