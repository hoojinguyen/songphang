import type { Context } from "hono";
import { createMiddleware } from "hono/factory";
import type { AppDeps, AppEnv } from "./app.js";
import { AppError } from "./errors.js";

type RateWindow = {
	count: number;
	expiresAt: number;
	warned?: boolean;
};

export function createRateLimiter(now: () => Date) {
	const windows = new Map<string, RateWindow>();

	function prune(time: number) {
		for (const [key, window] of windows) {
			if (window.expiresAt <= time) windows.delete(key);
		}
	}

	return {
		consumeQuota(options: {
			name: string;
			max: number;
			windowMs: number;
			subject: string;
		}): { allowed: boolean; notifyExceeded: boolean } {
			const time = now().getTime();
			prune(time);
			const key = JSON.stringify([options.name, options.subject]);
			const window = windows.get(key) ?? {
				count: 0,
				expiresAt: time + options.windowMs,
			};
			if (window.count >= options.max) {
				const notifyExceeded = !window.warned;
				window.warned = true;
				windows.set(key, window);
				return { allowed: false, notifyExceeded };
			}
			window.count += 1;
			windows.set(key, window);
			return { allowed: true, notifyExceeded: false };
		},
		limit(options: {
			name: string;
			max: number;
			windowMs: number;
			key: (context: Context<AppEnv>) => string | null;
		}) {
			return createMiddleware<AppEnv>(async (context, next) => {
				const subject = options.key(context);
				if (subject === null) {
					await next();
					return;
				}
				const time = now().getTime();
				prune(time);
				const key = JSON.stringify([options.name, subject]);
				const window = windows.get(key) ?? {
					count: 0,
					expiresAt: time + options.windowMs,
				};
				if (window.count >= options.max) {
					context.header(
						"Retry-After",
						String(Math.ceil((window.expiresAt - time) / 1000)),
					);
					throw new AppError(429, "RATE_LIMITED", "Too many requests");
				}
				window.count += 1;
				windows.set(key, window);
				await next();
			});
		},
	};
}

export function requireUploadLimit(deps: AppDeps) {
	return deps.rateLimiter.limit({
		name: "attachment_upload",
		max: 30,
		windowMs: 60 * 60 * 1000,
		key: (context) => context.var.user.id,
	});
}

export function requireCommentLimit(deps: AppDeps) {
	return deps.rateLimiter.limit({
		name: "comment_create",
		max: 20,
		windowMs: 60 * 1000,
		key: (context) => context.var.user.id,
	});
}
