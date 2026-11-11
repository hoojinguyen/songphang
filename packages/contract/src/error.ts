import { z } from "@hono/zod-openapi";

export const ErrorCode = z
	.enum(["VALIDATION_FAILED", "UNAUTHENTICATED", "NOT_FOUND", "INTERNAL"])
	.openapi("ErrorCode");
export type ErrorCode = z.infer<typeof ErrorCode>;

export const ErrorResponse = z
	.object({
		error: z.object({
			code: ErrorCode,
			message: z.string(),
			details: z.record(z.string(), z.unknown()).optional(),
			requestId: z.string(),
		}),
	})
	.openapi("ErrorResponse");
export type ErrorResponse = z.infer<typeof ErrorResponse>;
