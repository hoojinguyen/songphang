import { z } from "@hono/zod-openapi";

export const AppVersion = z
	.string()
	.max(32)
	.regex(/^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/)
	.openapi("AppVersion", {
		description: "Three-component numeric app version (major.minor.patch).",
		example: "1.0.0",
	});
export type AppVersion = z.infer<typeof AppVersion>;

export const MinAppVersion = z
	.object({
		ios: AppVersion,
		android: AppVersion,
	})
	.openapi("MinAppVersion");
export type MinAppVersion = z.infer<typeof MinAppVersion>;

export const FeaturesResponse = z
	.object({
		receiptReading: z.boolean(),
		sentenceAi: z.boolean(),
		telegram: z.boolean(),
		push: z.boolean(),
		appleSignIn: z.boolean(),
		errorAlerts: z.boolean(),
		minAppVersion: MinAppVersion,
	})
	.openapi("FeaturesResponse");
export type FeaturesResponse = z.infer<typeof FeaturesResponse>;
