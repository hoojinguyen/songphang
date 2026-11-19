import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	LoginRequest,
	ProvidersResponse,
	RegisterRequest,
	VerifyEmailRequest,
} from "@songphang/contract";
import { setCookie } from "hono/cookie";
import type { AppDeps, AppEnv } from "../app.js";
import { prepareAccountEmail, socketIp } from "../auth/account-limits.js";
import { requireSameOrigin, requireUser } from "../auth/middleware.js";
import { SESSION_COOKIE, sessionCookieAttributes } from "../auth/sessions.js";
import {
	getProviders,
	loginAccount,
	registerAccount,
	resendVerification,
	verifyEmail,
} from "../services/accounts.js";

const registerRoute = createRoute({
	method: "post",
	path: "/api/v1/auth/register",
	request: {
		body: {
			required: true,
			content: { "application/json": { schema: RegisterRequest } },
		},
	},
	responses: { 204: { description: "Registration processed" } },
});
const loginRoute = createRoute({
	method: "post",
	path: "/api/v1/auth/login",
	request: {
		headers: z.object({ "user-agent": z.string().max(1024).optional() }),
		body: {
			required: true,
			content: { "application/json": { schema: LoginRequest } },
		},
	},
	responses: { 204: { description: "Signed in" } },
});
const verifyRoute = createRoute({
	method: "post",
	path: "/api/v1/auth/verify-email",
	request: {
		body: {
			required: true,
			content: { "application/json": { schema: VerifyEmailRequest } },
		},
	},
	responses: { 204: { description: "Email verified" } },
});
const resendRoute = createRoute({
	method: "post",
	path: "/api/v1/auth/resend-verification",
	responses: { 204: { description: "Verification sent" } },
});
const providersRoute = createRoute({
	method: "get",
	path: "/api/v1/auth/providers",
	responses: {
		200: {
			description: "Available sign-in providers",
			content: { "application/json": { schema: ProvidersResponse } },
		},
	},
});
export function createLoginRateLimiters(deps: AppDeps) {
	return {
		loginIpLimit: deps.rateLimiter.limit({
			name: "login-ip",
			max: 10,
			windowMs: 15 * 60 * 1000,
			key: socketIp,
		}),
		loginEmailLimit: deps.rateLimiter.limit({
			name: "login-email",
			max: 5,
			windowMs: 15 * 60 * 1000,
			key: (context) => context.var.authEmail,
		}),
	};
}

export function registerAccountAuthRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	const sameOrigin = requireSameOrigin(deps.config);
	const registerLimit = deps.rateLimiter.limit({
		name: "register-ip",
		max: 5,
		windowMs: 60 * 60 * 1000,
		key: socketIp,
	});
	const { loginIpLimit, loginEmailLimit } = createLoginRateLimiters(deps);
	const resendLimit = deps.rateLimiter.limit({
		name: "resend-user",
		max: 3,
		windowMs: 60 * 60 * 1000,
		key: (context) => context.var.user.id,
	});
	app.openapi(
		{ ...registerRoute, middleware: [sameOrigin, registerLimit] },
		async (context) => {
			await registerAccount(deps, context.req.valid("json"));
			return context.body(null, 204);
		},
	);
	app.openapi(
		{
			...loginRoute,
			middleware: [
				sameOrigin,
				loginIpLimit,
				prepareAccountEmail,
				loginEmailLimit,
			],
		},
		async (context) => {
			const userAgent = context.req.valid("header")["user-agent"];
			const { session } = await loginAccount(deps, {
				request: context.req.valid("json"),
				client: "web",
				...(userAgent === undefined ? {} : { userAgent }),
			});
			setCookie(
				context,
				SESSION_COOKIE,
				session.token,
				sessionCookieAttributes(deps.config.appEnv),
			);
			return context.body(null, 204);
		},
	);
	app.openapi({ ...verifyRoute, middleware: [sameOrigin] }, async (context) => {
		await verifyEmail(deps, context.req.valid("json").token);
		return context.body(null, 204);
	});
	app.openapi(
		{
			...resendRoute,
			middleware: [requireUser(deps), sameOrigin, resendLimit],
		},
		async (context) => {
			await resendVerification(deps, context.var.user);
			return context.body(null, 204);
		},
	);
	app.openapi(providersRoute, (context) =>
		context.json(ProvidersResponse.parse(getProviders(deps)), 200),
	);
}
