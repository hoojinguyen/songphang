import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import { SendReminderRequest, SendReminderResponse } from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { requireGroupRole } from "../auth/group-access.js";
import { requireSameOrigin, requireUser } from "../auth/middleware.js";
import {
	requireVerifiedEmail,
	requireWriteLimit,
} from "../auth/verified-email.js";
import { sendReminders } from "../services/reminders.js";

export function registerReminderRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	app.openapi(
		createRoute({
			method: "post",
			path: "/api/v1/groups/{groupId}/reminders",
			middleware: [
				requireUser(deps),
				requireGroupRole(deps, "viewer"),
				requireVerifiedEmail(deps),
				requireWriteLimit(deps),
				requireSameOrigin(deps.config),
			],
			request: {
				params: z.object({ groupId: z.uuid() }),
				body: {
					required: true,
					content: { "application/json": { schema: SendReminderRequest } },
				},
			},
			responses: {
				200: {
					description: "Reminders sent or skipped",
					content: { "application/json": { schema: SendReminderResponse } },
				},
			},
		}),
		async (context) =>
			context.json(
				await sendReminders(deps, {
					groupId: context.var.groupAccess.groupId,
					userId: context.var.user.id,
					request: context.req.valid("json"),
				}),
				200,
			),
	);
}
