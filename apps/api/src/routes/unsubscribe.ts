import { createRoute, type OpenAPIHono } from "@hono/zod-openapi";
import { UnsubscribeRequest } from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { socketIp } from "../auth/account-limits.js";
import { requireSameOrigin } from "../auth/middleware.js";
import { AppError } from "../errors.js";
import { unsubscribeNotifications } from "../services/notifications.js";

export function registerUnsubscribeRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	const limit = deps.rateLimiter.limit({
		name: "unsubscribe",
		max: 30,
		windowMs: 60_000,
		key: (context) => socketIp(context),
	});

	app.openapi(
		createRoute({
			method: "post",
			path: "/api/v1/notifications/unsubscribe",
			middleware: [requireSameOrigin(deps.config), limit],
			request: {
				body: {
					required: true,
					content: { "application/json": { schema: UnsubscribeRequest } },
				},
			},
			responses: {
				204: { description: "Unsubscribed from notification emails" },
			},
		}),
		async (context) => {
			await unsubscribeNotifications(deps, context.req.valid("json").token);
			return context.body(null, 204);
		},
		(result) => {
			if (!result.success) {
				throw new AppError(404, "NOT_FOUND", "Resource not found");
			}
		},
	);
}
