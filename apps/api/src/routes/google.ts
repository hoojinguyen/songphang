import { randomBytes, timingSafeEqual } from "node:crypto";
import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	ErrorResponse,
	NativeClient,
	PkceCodeChallenge,
} from "@songphang/contract";
import { deleteCookie, getCookie, setCookie } from "hono/cookie";
import type { AppDeps, AppEnv } from "../app.js";
import {
	exchangeGoogleCode,
	googleAuthorizationUrl,
	safeRedirect,
} from "../auth/google.js";
import { SESSION_COOKIE, sessionCookieAttributes } from "../auth/sessions.js";
import { AppError } from "../errors.js";
import {
	googleSignIn,
	resolveGoogleUserId,
} from "../services/google-sign-in.js";
import { issueMobileExchangeCode } from "../services/mobile-auth.js";

const NATIVE_AUTH_CALLBACK_PREFIX = "songphang://auth";

const COOKIE_NAMES = {
	state: "sp_google_state",
	verifier: "sp_google_verifier",
	redirect: "sp_google_redirect",
	client: "sp_google_client",
	challenge: "sp_google_challenge",
};
const COOKIE_VALUES = z.object({
	state: z.string().regex(/^[A-Za-z0-9_-]{43}$/),
	verifier: z.string().regex(/^[A-Za-z0-9_-]{43}$/),
	redirect: z.string().max(2048).optional(),
});
const authorizeRoute = createRoute({
	method: "get",
	path: "/api/v1/auth/google",
	request: {
		query: z.object({
			redirect: z.string().max(2048).optional(),
			client: NativeClient.optional(),
			code_challenge: z.string().max(128).optional(),
		}),
	},
	responses: {
		302: { description: "Google authorization" },
		400: {
			description: "Invalid native authorization parameters",
			content: { "application/json": { schema: ErrorResponse } },
		},
	},
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
		const query = context.req.valid("query");
		if (query.client !== undefined) {
			const challenge = PkceCodeChallenge.safeParse(query.code_challenge);
			if (!challenge.success) {
				throw new AppError(
					400,
					"VALIDATION_FAILED",
					"Native sign-in requires a valid PKCE S256 code_challenge",
				);
			}
			const state = randomBytes(32).toString("base64url");
			const verifier = randomBytes(32).toString("base64url");
			setCookie(context, COOKIE_NAMES.state, state, attributes);
			setCookie(context, COOKIE_NAMES.verifier, verifier, attributes);
			setCookie(context, COOKIE_NAMES.client, query.client, attributes);
			setCookie(context, COOKIE_NAMES.challenge, challenge.data, attributes);
			deleteCookie(context, COOKIE_NAMES.redirect, attributes);
			return context.redirect(
				googleAuthorizationUrl(deps.config, { state, verifier }),
				302,
			);
		}
		const state = randomBytes(32).toString("base64url");
		const verifier = randomBytes(32).toString("base64url");
		setCookie(context, COOKIE_NAMES.state, state, attributes);
		setCookie(context, COOKIE_NAMES.verifier, verifier, attributes);
		setCookie(
			context,
			COOKIE_NAMES.redirect,
			safeRedirect(query.redirect),
			attributes,
		);
		deleteCookie(context, COOKIE_NAMES.client, attributes);
		deleteCookie(context, COOKIE_NAMES.challenge, attributes);
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
		const rawClient = cookieHeader.success
			? getCookie(context, COOKIE_NAMES.client)
			: undefined;
		const rawChallenge = cookieHeader.success
			? getCookie(context, COOKIE_NAMES.challenge)
			: undefined;
		const cookies = cookieHeader.success
			? COOKIE_VALUES.safeParse({
					state: getCookie(context, COOKIE_NAMES.state),
					verifier: getCookie(context, COOKIE_NAMES.verifier),
					redirect: getCookie(context, COOKIE_NAMES.redirect),
				})
			: null;
		for (const name of Object.values(COOKIE_NAMES))
			deleteCookie(context, name, attributes);

		const parsedClient = NativeClient.safeParse(rawClient);
		const parsedChallenge = PkceCodeChallenge.safeParse(rawChallenge);
		const isNative = parsedClient.success && parsedChallenge.success;
		const hasPartialNative =
			(rawClient !== undefined || rawChallenge !== undefined) && !isNative;
		const failureRedirect = isNative
			? `${NATIVE_AUTH_CALLBACK_PREFIX}?error=google`
			: "/login?error=google";

		const query = context.req.valid("query");
		if (
			hasPartialNative ||
			!cookies?.success ||
			!query.state ||
			!query.code ||
			!/^[A-Za-z0-9_-]{43}$/.test(query.state) ||
			!timingSafeEqual(
				Buffer.from(query.state),
				Buffer.from(cookies.data.state),
			)
		)
			return context.redirect(failureRedirect, 302);
		try {
			const claims = await exchangeGoogleCode(deps.config, {
				code: query.code,
				verifier: cookies.data.verifier,
			});
			if (isNative) {
				const resolved = await resolveGoogleUserId(deps, claims);
				if (resolved.kind === "google_unverified") {
					return context.redirect(
						`${NATIVE_AUTH_CALLBACK_PREFIX}?error=google_unverified`,
						302,
					);
				}
				const exchangeCode = await issueMobileExchangeCode(deps, {
					userId: resolved.userId,
					codeChallenge: parsedChallenge.data,
					client: parsedClient.data,
				});
				context.header("Cache-Control", "no-store");
				return context.redirect(
					`${NATIVE_AUTH_CALLBACK_PREFIX}?code=${encodeURIComponent(exchangeCode)}`,
					302,
				);
			}
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
			return context.redirect(failureRedirect, 302);
		}
	});
}
