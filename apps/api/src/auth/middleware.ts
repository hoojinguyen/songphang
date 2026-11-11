import { z } from "@hono/zod-openapi";
import { getCookie } from "hono/cookie";
import { createMiddleware } from "hono/factory";
import type { AppDeps, AppEnv } from "../app.js";
import type { Config } from "../config.js";
import { AppError } from "../errors.js";
import { findSessionUser, SESSION_COOKIE } from "./sessions.js";

const SESSION_HEADERS = z.object({
	authorization: z.string().max(256).optional(),
	cookie: z.string().max(8192).optional(),
});
const ORIGIN_HEADER = z.string().max(2048).optional();

export function requireUser(deps: AppDeps) {
	return createMiddleware<AppEnv>(async (context, next) => {
		const headers = SESSION_HEADERS.safeParse({
			authorization: context.req.header("Authorization"),
			cookie: context.req.header("Cookie"),
		});
		if (!headers.success)
			throw new AppError(401, "UNAUTHENTICATED", "Authentication required");
		const bearerToken =
			headers.data.authorization?.match(/^Bearer (.+)$/i)?.[1];
		const token = bearerToken ?? getCookie(context, SESSION_COOKIE) ?? "";
		const user = await findSessionUser(deps.db, token, deps.now());
		if (user === null)
			throw new AppError(401, "UNAUTHENTICATED", "Authentication required");
		context.set("user", user);
		context.set("sessionToken", token);
		await next();
	});
}

export function requireSameOrigin(config: Config) {
	return createMiddleware<AppEnv>(async (context, next) => {
		const origin = ORIGIN_HEADER.safeParse(context.req.header("Origin"));
		if (
			!origin.success ||
			(origin.data !== undefined && origin.data !== config.webOrigin)
		) {
			throw new AppError(
				400,
				"VALIDATION_FAILED",
				"Request origin is not allowed",
			);
		}
		await next();
	});
}
