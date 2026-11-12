import { createRoute, type OpenAPIHono } from "@hono/zod-openapi";
import {
	ChangePasswordRequest,
	ForgotPasswordRequest,
	ResetPasswordRequest,
} from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { prepareAccountEmail, socketIp } from "../auth/account-limits.js";
import { requireSameOrigin, requireUser } from "../auth/middleware.js";
import {
	changePassword,
	forgotPassword,
	resetPassword,
} from "../services/password-recovery.js";

const forgotRoute = createRoute({
	method: "post",
	path: "/api/v1/auth/forgot-password",
	request: {
		body: {
			required: true,
			content: { "application/json": { schema: ForgotPasswordRequest } },
		},
	},
	responses: { 204: { description: "Reset request processed" } },
});
const resetRoute = createRoute({
	method: "post",
	path: "/api/v1/auth/reset-password",
	request: {
		body: {
			required: true,
			content: { "application/json": { schema: ResetPasswordRequest } },
		},
	},
	responses: { 204: { description: "Password reset" } },
});
const changeRoute = createRoute({
	method: "post",
	path: "/api/v1/auth/change-password",
	request: {
		body: {
			required: true,
			content: { "application/json": { schema: ChangePasswordRequest } },
		},
	},
	responses: { 204: { description: "Password changed" } },
});
export function registerPasswordRecoveryRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	const sameOrigin = requireSameOrigin(deps.config);
	const ipLimit = deps.rateLimiter.limit({
		name: "forgot-ip",
		max: 10,
		windowMs: 60 * 60 * 1000,
		key: socketIp,
	});
	const emailLimit = deps.rateLimiter.limit({
		name: "forgot-email",
		max: 3,
		windowMs: 60 * 60 * 1000,
		key: (context) => context.var.authEmail,
	});
	app.openapi(
		{
			...forgotRoute,
			middleware: [sameOrigin, ipLimit, prepareAccountEmail, emailLimit],
		},
		async (context) => {
			await forgotPassword(deps, context.req.valid("json"));
			return context.body(null, 204);
		},
	);
	app.openapi({ ...resetRoute, middleware: [sameOrigin] }, async (context) => {
		await resetPassword(deps, context.req.valid("json"));
		return context.body(null, 204);
	});
	app.openapi(
		{ ...changeRoute, middleware: [sameOrigin, requireUser(deps)] },
		async (context) => {
			await changePassword(deps, {
				userId: context.var.user.id,
				sessionToken: context.var.sessionToken,
				request: context.req.valid("json"),
			});
			return context.body(null, 204);
		},
	);
}
