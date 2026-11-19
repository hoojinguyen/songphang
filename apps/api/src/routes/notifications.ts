import { createRoute, type OpenAPIHono } from "@hono/zod-openapi";
import {
	MarkNotificationsReadRequest,
	NotificationSettingsDto,
	NotificationsListQuery,
	NotificationsListResponse,
	UnreadCountResponse,
	UpdateNotificationSettingsRequest,
} from "@songphang/contract";
import type { AppDeps, AppEnv } from "../app.js";
import { requireSameOrigin, requireUser } from "../auth/middleware.js";
import { requireWriteLimit } from "../auth/verified-email.js";
import {
	getMyNotificationSettings,
	getUnreadCount,
	listNotifications,
	readNotifications,
	updateMyNotificationSettings,
} from "../services/notifications.js";

export function registerNotificationRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	const signedIn = [requireUser(deps)];

	app.openapi(
		createRoute({
			method: "get",
			path: "/api/v1/me/notifications",
			middleware: signedIn,
			request: { query: NotificationsListQuery },
			responses: {
				200: {
					description: "User notifications",
					content: {
						"application/json": { schema: NotificationsListResponse },
					},
				},
			},
		}),
		async (context) =>
			context.json(
				await listNotifications(deps, {
					userId: context.var.user.id,
					query: context.req.valid("query"),
				}),
				200,
			),
	);

	app.openapi(
		createRoute({
			method: "get",
			path: "/api/v1/me/notifications/unread-count",
			middleware: signedIn,
			responses: {
				200: {
					description: "Unread notification count",
					content: { "application/json": { schema: UnreadCountResponse } },
				},
			},
		}),
		async (context) =>
			context.json(await getUnreadCount(deps, context.var.user.id), 200),
	);

	app.openapi(
		createRoute({
			method: "post",
			path: "/api/v1/me/notifications/read",
			middleware: [
				...signedIn,
				requireWriteLimit(deps),
				requireSameOrigin(deps.config),
			],
			request: {
				body: {
					required: true,
					content: {
						"application/json": { schema: MarkNotificationsReadRequest },
					},
				},
			},
			responses: {
				204: { description: "Notifications marked read" },
			},
		}),
		async (context) => {
			await readNotifications(deps, {
				userId: context.var.user.id,
				request: context.req.valid("json"),
			});
			return context.body(null, 204);
		},
	);

	app.openapi(
		createRoute({
			method: "get",
			path: "/api/v1/me/notification-settings",
			middleware: signedIn,
			responses: {
				200: {
					description: "Notification email settings",
					content: {
						"application/json": { schema: NotificationSettingsDto },
					},
				},
			},
		}),
		async (context) =>
			context.json(
				await getMyNotificationSettings(deps, context.var.user.id),
				200,
			),
	);

	app.openapi(
		createRoute({
			method: "put",
			path: "/api/v1/me/notification-settings",
			middleware: [
				...signedIn,
				requireWriteLimit(deps),
				requireSameOrigin(deps.config),
			],
			request: {
				body: {
					required: true,
					content: {
						"application/json": { schema: UpdateNotificationSettingsRequest },
					},
				},
			},
			responses: {
				200: {
					description: "Updated notification email settings",
					content: {
						"application/json": { schema: NotificationSettingsDto },
					},
				},
			},
		}),
		async (context) =>
			context.json(
				await updateMyNotificationSettings(deps, {
					userId: context.var.user.id,
					request: context.req.valid("json"),
				}),
				200,
			),
	);
}
