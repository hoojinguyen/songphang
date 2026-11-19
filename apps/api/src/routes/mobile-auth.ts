import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	ErrorResponse,
	TokenLoginRequest,
	TokenLoginResponse,
} from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { prepareAccountEmail } from "../auth/account-limits.js";
import { loginAccount } from "../services/accounts.js";
import { createLoginRateLimiters } from "./account-auth.js";

const tokenLoginRoute = createRoute({
	method: "post",
	path: "/api/v1/auth/token",
	request: {
		headers: z.object({ "user-agent": z.string().max(1024).optional() }),
		body: {
			required: true,
			content: { "application/json": { schema: TokenLoginRequest } },
		},
	},
	responses: {
		200: {
			description: "Native session issued",
			content: { "application/json": { schema: TokenLoginResponse } },
		},
		401: {
			description: "Invalid credentials",
			content: { "application/json": { schema: ErrorResponse } },
		},
		429: {
			description: "Too many login attempts",
			content: { "application/json": { schema: ErrorResponse } },
		},
	},
});

export function registerMobileAuthRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	const { loginIpLimit, loginEmailLimit } = createLoginRateLimiters(deps);
	app.openapi(
		{
			...tokenLoginRoute,
			middleware: [loginIpLimit, prepareAccountEmail, loginEmailLimit],
		},
		async (context) => {
			const body = context.req.valid("json");
			const userAgent = context.req.valid("header")["user-agent"];
			const result = await loginAccount(deps, {
				request: { email: body.email, password: body.password },
				client: body.client,
				deviceName: body.deviceName,
				...(userAgent === undefined ? {} : { userAgent }),
			});
			context.header("Cache-Control", "no-store");
			return context.json(
				TokenLoginResponse.parse({
					token: result.session.token,
					user: result.user,
				}),
				200,
			);
		},
	);
}
