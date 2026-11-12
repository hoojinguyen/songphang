import type { Context } from "hono";
import { createMiddleware } from "hono/factory";
import type { AppEnv } from "./app.js";
import { AppError } from "./errors.js";
export function createRateLimiter(now: () => Date) {
	const windows = new Map<string, { count: number; expiresAt: number }>();
	return {
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
				for (const [key, window] of windows)
					if (window.expiresAt <= time) windows.delete(key);
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
