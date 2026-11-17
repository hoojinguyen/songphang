import { z } from "@hono/zod-openapi";

export const JOB_NAMES = {
	heartbeat: "heartbeat",
	cleanupAttachments: "cleanup-attachments",
	deleteFiles: "delete-files",
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
]);
export type GroupEventResource = z.infer<typeof GroupEventResource>;

export const GroupEventNotification = z.object({
	groupId: z.uuid(),
	resources: z.array(GroupEventResource).min(1).max(10),
});
export type GroupEventNotification = z.infer<typeof GroupEventNotification>;
