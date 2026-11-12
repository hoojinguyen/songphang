import { randomBytes, timingSafeEqual } from "node:crypto";
import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import { deleteCookie, getCookie, setCookie } from "hono/cookie";
import type { AppDeps, AppEnv } from "../app.js";
import {
	exchangeGoogleCode,
	googleAuthorizationUrl,
	safeRedirect,
} from "../auth/google.js";
import { SESSION_COOKIE, sessionCookieAttributes } from "../auth/sessions.js";
import { googleSignIn } from "../services/google-sign-in.js";

const COOKIE_NAMES = {
	state: "sp_google_state",
	verifier: "sp_google_verifier",
	redirect: "sp_google_redirect",
};
const COOKIE_VALUES = z.object({
	state: z.string().regex(/^[A-Za-z0-9_-]{43}$/),
	verifier: z.string().regex(/^[A-Za-z0-9_-]{43}$/),
	redirect: z.string().max(2048).optional(),
});
const authorizeRoute = createRoute({
	method: "get",
	path: "/api/v1/auth/google",
	request: { query: z.object({ redirect: z.string().max(2048).optional() }) },
	responses: { 302: { description: "Google authorization" } },
});
const callbackRoute = createRoute({
	method: "get",
	path: "/api/v1/auth/google/callback",
	request: {
		query: z.object({
			state: z.string().max(2048).optional(),
			code: z.string().max(2048).optional(),
		}),
	},
	responses: { 302: { description: "Sign-in outcome" } },
});
export function registerGoogleRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	if (!deps.config.googleClientId || !deps.config.googleClientSecret) return;
	const attributes = {
		httpOnly: true,
		sameSite: "Lax",
		path: "/api/v1/auth/google",
		secure: deps.config.appEnv === "production",
		maxAge: 600,
	} as const;
	app.openapi(authorizeRoute, (context) => {
		const state = randomBytes(32).toString("base64url");
		const verifier = randomBytes(32).toString("base64url");
		setCookie(context, COOKIE_NAMES.state, state, attributes);
		setCookie(context, COOKIE_NAMES.verifier, verifier, attributes);
		setCookie(
			context,
			COOKIE_NAMES.redirect,
			safeRedirect(context.req.valid("query").redirect),
			attributes,
		);
		return context.redirect(
			googleAuthorizationUrl(deps.config, { state, verifier }),
			302,
		);
	});
	app.openapi(callbackRoute, async (context) => {
		const cookieHeader = z
			.string()
			.max(8192)
			.safeParse(context.req.header("Cookie") ?? "");
		const cookies = cookieHeader.success
			? COOKIE_VALUES.safeParse({
					state: getCookie(context, COOKIE_NAMES.state),
					verifier: getCookie(context, COOKIE_NAMES.verifier),
					redirect: getCookie(context, COOKIE_NAMES.redirect),
				})
			: null;
		for (const name of Object.values(COOKIE_NAMES))
			deleteCookie(context, name, attributes);
		const query = context.req.valid("query");
		if (
			!cookies?.success ||
			!query.state ||
			!query.code ||
			!/^[A-Za-z0-9_-]{43}$/.test(query.state) ||
			!timingSafeEqual(
				Buffer.from(query.state),
				Buffer.from(cookies.data.state),
			)
		)
			return context.redirect("/login?error=google", 302);
		try {
			const claims = await exchangeGoogleCode(deps.config, {
				code: query.code,
				verifier: cookies.data.verifier,
			});
			const result = await googleSignIn(deps, claims);
			if (result.kind === "google_unverified")
				return context.redirect("/login?error=google_unverified", 302);
			setCookie(
				context,
				SESSION_COOKIE,
				result.session.token,
				sessionCookieAttributes(deps.config.appEnv),
			);
			return context.redirect(safeRedirect(cookies.data.redirect), 302);
		} catch {
			return context.redirect("/login?error=google", 302);
		}
	});
}
