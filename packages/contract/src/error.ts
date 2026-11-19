import { z } from "@hono/zod-openapi";

export const ErrorCode = z
	.enum([
		"VALIDATION_FAILED",
		"REQUEST_NOT_PENDING",
		"REQUEST_ALREADY_PENDING",
		"VERSION_CONFLICT",
		"UNAUTHENTICATED",
		"NOT_FOUND",
		"INTERNAL",
		"FORBIDDEN",
		"INVALID_CREDENTIALS",
		"EMAIL_NOT_VERIFIED",
		"TOKEN_INVALID",
		"WEAK_PASSWORD",
		"RATE_LIMITED",
		"INVITE_INVALID",
		"MEMBER_ALREADY_CLAIMED",
		"OWNER_REQUIRED",
		"IDEMPOTENCY_KEY_REUSED",
		"MEMBER_NOT_IN_GROUP",
		"MEMBER_HAS_TRANSACTIONS",
		"PAYER_TOTAL_MISMATCH",
		"SPLIT_TOTAL_MISMATCH",
		"CATEGORY_EXISTS",
		"LIMIT_REACHED",
		"FUND_CANNOT_SHARE",
		"FUND_NOT_EMPTY",
		"FUND_EXISTS",
		"STORAGE_QUOTA_EXCEEDED",
		"AI_QUOTA_EXCEEDED",
		"ITEM_UNASSIGNED",
		"DISPUTE_ALREADY_OPEN",
		"DISPUTE_NOT_OPEN",
		"REMINDER_TOO_SOON",
		"MEMBER_NOT_LINKED",
		"CHAT_IDENTITY_TAKEN",
		"APPROVAL_NOT_PENDING",
	])
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
