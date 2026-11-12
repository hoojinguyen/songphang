import { getConnInfo } from "@hono/node-server/conninfo";
import { z } from "@hono/zod-openapi";
import { EmailAddress } from "@songphang/contract";
import type { Context } from "hono";
import { createMiddleware } from "hono/factory";
import type { AppEnv } from "../app.js";
import { AppError } from "../errors.js";
export function socketIp(context: Context<AppEnv>): string {
	return getConnInfo(context).remote.address ?? "unknown";
}
export const prepareAccountEmail = createMiddleware<AppEnv>(
	async (context, next) => {
		let body: unknown;
		try {
			body = await context.req.json();
		} catch {
			throw new AppError(400, "VALIDATION_FAILED", "Invalid request body");
		}
		const parsed = z.object({ email: EmailAddress }).safeParse(body);
		if (!parsed.success)
			throw new AppError(400, "VALIDATION_FAILED", "Invalid email address");
		context.set("authEmail", parsed.data.email);
		await next();
	},
);
