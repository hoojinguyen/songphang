import { z } from "@hono/zod-openapi";

export const NotificationPayload = z
	.discriminatedUnion("kind", [
		z.object({
			kind: z.literal("expense_added"),
			actorName: z.string(),
			groupName: z.string(),
			transactionId: z.uuid(),
			description: z.string(),
			share: z.int().nonnegative(),
		}),
		z.object({
			kind: z.literal("expense_changed"),
			actorName: z.string(),
			groupName: z.string(),
			transactionId: z.uuid(),
			description: z.string(),
			action: z.enum(["edited", "deleted"]),
		}),
		z.object({
			kind: z.literal("comment_added"),
			actorName: z.string(),
			groupName: z.string(),
			transactionId: z.uuid(),
			description: z.string(),
		}),
		z.object({
			kind: z.literal("dispute_opened"),
			actorName: z.string(),
			groupName: z.string(),
			transactionId: z.uuid(),
			description: z.string(),
			reason: z.string(),
		}),
		z.object({
			kind: z.literal("dispute_resolved"),
			actorName: z.string(),
			groupName: z.string(),
			transactionId: z.uuid(),
			description: z.string(),
		}),
		z.object({
			kind: z.literal("settlement_requested"),
			actorName: z.string(),
			groupName: z.string(),
			amount: z.int().positive(),
		}),
		z.object({
			kind: z.literal("settlement_confirmed"),
			actorName: z.string(),
			groupName: z.string(),
			amount: z.int().positive(),
		}),
		z.object({
			kind: z.literal("settlement_rejected"),
			actorName: z.string(),
			groupName: z.string(),
			amount: z.int().positive(),
		}),
		z.object({
			kind: z.literal("debt_reminder"),
			actorName: z.string(),
			groupName: z.string(),
			toName: z.string(),
			amount: z.int().positive(),
		}),
		z.object({
			kind: z.literal("approval_requested"),
			actorName: z.string(),
			groupName: z.string(),
			transactionId: z.uuid(),
			description: z.string(),
			amount: z.int().positive(),
		}),
		z.object({
			kind: z.literal("approval_decided"),
			actorName: z.string(),
			groupName: z.string(),
			transactionId: z.uuid(),
			description: z.string(),
			decision: z.enum(["approved", "rejected"]),
		}),
		z.object({
			kind: z.literal("budget_state"),
			actorName: z.string(),
			groupName: z.string(),
			state: z.enum(["near", "over"]),
		}),
	])
	.openapi("NotificationPayload");
export type NotificationPayload = z.infer<typeof NotificationPayload>;
export type NotificationKind = NotificationPayload["kind"];

export const NotificationDto = z
	.object({
		id: z.uuid(),
		kind: z.string(),
		groupId: z.uuid(),
		payload: z.union([NotificationPayload, z.record(z.string(), z.unknown())]),
		read: z.boolean(),
		createdAt: z.iso.datetime(),
	})
	.openapi("NotificationDto");
export type NotificationDto = z.infer<typeof NotificationDto>;

export const NotificationsListQuery = z.object({
	cursor: z.string().max(256).optional(),
	limit: z.coerce.number().int().min(1).max(50).default(30),
});
export type NotificationsListQuery = z.infer<typeof NotificationsListQuery>;

export const NotificationsListResponse = z
	.object({
		notifications: z.array(NotificationDto),
		nextCursor: z.string().nullable(),
	})
	.openapi("NotificationsListResponse");
export type NotificationsListResponse = z.infer<
	typeof NotificationsListResponse
>;

export const UnreadCountResponse = z
	.object({ count: z.int().nonnegative() })
	.openapi("UnreadCountResponse");
export type UnreadCountResponse = z.infer<typeof UnreadCountResponse>;

export const MarkNotificationsReadRequest = z
	.union([
		z.object({ ids: z.array(z.uuid()).min(1).max(100) }),
		z.object({ all: z.literal(true) }),
	])
	.openapi("MarkNotificationsReadRequest");
export type MarkNotificationsReadRequest = z.infer<
	typeof MarkNotificationsReadRequest
>;

export const UpdateGroupMuteRequest = z
	.object({ muted: z.boolean() })
	.openapi("UpdateGroupMuteRequest");
export type UpdateGroupMuteRequest = z.infer<typeof UpdateGroupMuteRequest>;

export const GroupMuteResponse = z
	.object({ muted: z.boolean() })
	.openapi("GroupMuteResponse");
export type GroupMuteResponse = z.infer<typeof GroupMuteResponse>;

export const NotificationSettingsDto = z
	.object({
		emailImmediate: z.boolean(),
		emailDigest: z.boolean(),
	})
	.openapi("NotificationSettingsDto");
export type NotificationSettingsDto = z.infer<typeof NotificationSettingsDto>;

export const UpdateNotificationSettingsRequest = z
	.object({
		emailImmediate: z.boolean().optional(),
		emailDigest: z.boolean().optional(),
	})
	.refine((value) => Object.keys(value).length > 0)
	.openapi("UpdateNotificationSettingsRequest");
export type UpdateNotificationSettingsRequest = z.infer<
	typeof UpdateNotificationSettingsRequest
>;

export const UnsubscribeRequest = z
	.object({ token: z.string().min(1).max(256) })
	.openapi("UnsubscribeRequest");
export type UnsubscribeRequest = z.infer<typeof UnsubscribeRequest>;
