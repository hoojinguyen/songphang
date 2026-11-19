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
const FORBIDDEN_QUERY_CREDENTIAL_KEYS = [
	"token",
	"access_token",
	"session",
	"session_token",
	"authorization",
] as const;

export function requireUser(deps: AppDeps) {
	return createMiddleware<AppEnv>(async (context, next) => {
		const query = context.req.query();
		for (const key of FORBIDDEN_QUERY_CREDENTIAL_KEYS) {
			if (key in query) {
				throw new AppError(
					400,
					"VALIDATION_FAILED",
					"Session credentials are not allowed in query parameters",
				);
			}
		}
		const headers = SESSION_HEADERS.safeParse({
			authorization: context.req.header("Authorization"),
			cookie: context.req.header("Cookie"),
		});
		if (!headers.success)
			throw new AppError(401, "UNAUTHENTICATED", "Authentication required");
		const bearerToken =
			headers.data.authorization?.match(/^Bearer (.+)$/i)?.[1];
		const cookieToken = getCookie(context, SESSION_COOKIE);
		const hasCookieHeader = headers.data.cookie !== undefined;
		const token = bearerToken ?? cookieToken ?? "";
		const user = await findSessionUser(deps.db, token, deps.now());
		if (user === null)
			throw new AppError(401, "UNAUTHENTICATED", "Authentication required");
		const transport =
			bearerToken !== undefined
				? hasCookieHeader
					? "mixed"
					: "bearer"
				: "cookie";
		context.set("user", user);
		context.set("sessionToken", token);
		context.set("sessionTransport", transport);
		await next();
	});
}

export function requireSameOrigin(config: Config) {
	return createMiddleware<AppEnv>(async (context, next) => {
		const hasCookieHeader = context.req.header("Cookie") !== undefined;
		const hasBearerHeader = /^Bearer \S+$/i.test(
			context.req.header("Authorization") ?? "",
		);
		// Bearer-only requests carry explicit non-ambient credentials and may omit Origin.
		// Requests with any Cookie header (including mixed Cookie + Bearer) remain on the web same-origin path.
		if (hasBearerHeader && !hasCookieHeader) {
			await next();
			return;
		}
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
