import { z } from "@hono/zod-openapi";

export const FeaturesResponse = z
	.object({
		receiptReading: z.boolean(),
		sentenceAi: z.boolean(),
		telegram: z.boolean(),
		push: z.boolean(),
		appleSignIn: z.boolean(),
		errorAlerts: z.boolean(),
	})
	.openapi("FeaturesResponse");
