import { createMiddleware } from "hono/factory";
import type { AppDeps, AppEnv } from "../app.js";
import { AppError } from "../errors.js";
export function requireVerifiedEmail(_deps: AppDeps) {
	return createMiddleware<AppEnv>(async (context, next) => {
		if (!context.var.user.emailVerified)
			throw new AppError(
				403,
				"EMAIL_NOT_VERIFIED",
				"Email verification required",
			);
		await next();
	});
}
export function requireWriteLimit(deps: AppDeps) {
	return deps.rateLimiter.limit({
		name: "write",
		max: 60,
		windowMs: 60000,
		key: (context) => context.var.user.id,
	});
}
