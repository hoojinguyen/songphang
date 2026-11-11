import type { Hook } from "@hono/zod-openapi";
import { type ErrorCode, ErrorResponse } from "@songphang/contract";
import type { Context } from "hono";
import { HTTPException } from "hono/http-exception";
import type { AppEnv } from "./app.js";

export class AppError extends Error {
	constructor(
		readonly status: number,
		readonly code: ErrorCode,
		message: string,
		readonly details?: Record<string, unknown>,
	) {
		super(message);
		this.name = "AppError";
	}
}

export const validateRequest: Hook<unknown, AppEnv, string, void> = (
	result,
) => {
	if (result.success) return;
	const fieldErrors = new Map<string, string[]>();
	for (const issue of result.error.issues) {
		const field = issue.path.join(".") || "body";
		fieldErrors.set(field, [...(fieldErrors.get(field) ?? []), issue.message]);
	}
	throw new AppError(
		400,
		"VALIDATION_FAILED",
		"Request validation failed",
		Object.fromEntries(fieldErrors),
	);
};

export function handleError(error: Error, context: Context<AppEnv>): Response {
	const requestId = context.get("requestId");
	let appError: AppError;
	if (error instanceof AppError) {
		appError = error;
	} else if (error instanceof HTTPException && error.status === 400) {
		appError = new AppError(400, "VALIDATION_FAILED", "Invalid request body");
	} else {
		console.error(
			JSON.stringify({
				requestId,
				error: { name: error.name, message: error.message, stack: error.stack },
			}),
		);
		appError = new AppError(500, "INTERNAL", "An internal error occurred");
	}
	const body = ErrorResponse.parse({
		error: {
			code: appError.code,
			message: appError.message,
			...(appError.details === undefined ? {} : { details: appError.details }),
			requestId,
		},
	});
	return new Response(JSON.stringify(body), {
		status: appError.status,
		headers: { "Content-Type": "application/json", "X-Request-Id": requestId },
	});
}
