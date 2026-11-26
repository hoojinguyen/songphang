import { z } from "@hono/zod-openapi";

export const JOB_NAMES = {
	heartbeat: "heartbeat",
	cleanupAttachments: "cleanup-attachments",
	deleteFiles: "delete-files",
	readReceipt: "read-receipt",
	sendNotificationMail: "send-notification-mail",
	sendPush: "send-push",
	sendDigest: "send-digest",
	pruneNotifications: "prune-notifications",
	autoReminders: "auto-reminders",
	pruneBotData: "prune-bot-data",
} as const;

export const HeartbeatPayload = z.object({});
export type HeartbeatPayload = z.infer<typeof HeartbeatPayload>;

export const CleanupAttachmentsPayload = z.object({});
export type CleanupAttachmentsPayload = z.infer<
	typeof CleanupAttachmentsPayload
>;

export const DeleteFilesPayload = z.object({
	keys: z.array(z.string().regex(/^[0-9a-f-]{36}\/[0-9a-f-]{36}$/)).max(10000),
});
export type DeleteFilesPayload = z.infer<typeof DeleteFilesPayload>;

export const ReadReceiptPayload = z.object({
	scanId: z.uuid(),
	reservationId: z.uuid(),
});
export type ReadReceiptPayload = z.infer<typeof ReadReceiptPayload>;

export const SendNotificationMailPayload = z.object({
	notificationId: z.uuid(),
});
export type SendNotificationMailPayload = z.infer<
	typeof SendNotificationMailPayload
>;

export const SendPushPayload = z.object({
	notificationId: z.uuid(),
});
export type SendPushPayload = z.infer<typeof SendPushPayload>;

export const SendDigestPayload = z.object({});
export type SendDigestPayload = z.infer<typeof SendDigestPayload>;

export const PruneNotificationsPayload = z.object({});
export type PruneNotificationsPayload = z.infer<
	typeof PruneNotificationsPayload
>;

export const AutoRemindersPayload = z.object({});
export type AutoRemindersPayload = z.infer<typeof AutoRemindersPayload>;

export const PruneBotDataPayload = z.object({});
export type PruneBotDataPayload = z.infer<typeof PruneBotDataPayload>;

export const GroupEventResource = z.enum([
	"group",
	"members",
	"users",
	"transactions",
	"balances",
	"activity",
	"settlementRequests",
	"categories",
	"budget",
	"receiptScans",
	"comments",
	"settlementCycles",
]);
export type GroupEventResource = z.infer<typeof GroupEventResource>;

export const GroupEventNotification = z.object({
	groupId: z.uuid(),
	resources: z.array(GroupEventResource).min(1).max(10),
});
export type GroupEventNotification = z.infer<typeof GroupEventNotification>;
