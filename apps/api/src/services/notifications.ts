import { createHash } from "node:crypto";
import { z } from "@hono/zod-openapi";
import {
	GroupMuteResponse,
	type MarkNotificationsReadRequest,
	NotificationDto,
	NotificationSettingsDto,
	type NotificationsListQuery,
	NotificationsListResponse,
	UnreadCountResponse,
	type UpdateNotificationSettingsRequest,
} from "@songphang/contract";
import {
	countUnreadNotifications,
	getNotificationSettings,
	listUserNotifications,
	markNotificationsRead,
	type NotificationCursor,
	type NotificationRow,
	unsubscribeByTokenHash,
	updateGroupUserMuted,
	upsertNotificationSettings,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { getGroupAccess } from "../auth/group-access.js";
import { AppError } from "../errors.js";

const CURSOR_SCHEMA = z.object({ createdAt: z.iso.datetime(), id: z.uuid() });

function decodeCursor(cursor: string | undefined): NotificationCursor | null {
	if (cursor === undefined) return null;
	try {
		if (!/^[A-Za-z0-9_-]+$/.test(cursor))
			throw new Error("Invalid cursor encoding");
		return CURSOR_SCHEMA.parse(
			JSON.parse(Buffer.from(cursor, "base64url").toString("utf8")),
		);
	} catch {
		throw new AppError(400, "VALIDATION_FAILED", "Invalid cursor");
	}
}

function toNotificationDto(row: NotificationRow): NotificationDto {
	return NotificationDto.parse({
		id: row.id,
		kind: row.kind,
		groupId: row.groupId,
		payload: row.payload,
		read: row.readAt !== null,
		createdAt: row.createdAt.toISOString(),
	});
}

export async function listNotifications(
	deps: AppDeps,
	input: { userId: string; query: NotificationsListQuery },
): Promise<NotificationsListResponse> {
	const cursor = decodeCursor(input.query.cursor);
	return deps.db.transaction(
		async (executor) => {
			const rows = await listUserNotifications(executor, {
				userId: input.userId,
				limit: input.query.limit + 1,
				cursor,
			});
			const page = rows.slice(0, input.query.limit);
			const last = page.at(-1);
			const nextCursor =
				rows.length > input.query.limit && last !== undefined
					? Buffer.from(
							JSON.stringify({
								createdAt: last.createdAt.toISOString(),
								id: last.id,
							}),
						).toString("base64url")
					: null;
			return NotificationsListResponse.parse({
				notifications: page.map(toNotificationDto),
				nextCursor,
			});
		},
		{ isolationLevel: "repeatable read", accessMode: "read only" },
	);
}

export async function getUnreadCount(
	deps: AppDeps,
	userId: string,
): Promise<UnreadCountResponse> {
	const count = await countUnreadNotifications(deps.db, userId);
	return UnreadCountResponse.parse({ count });
}

export async function readNotifications(
	deps: AppDeps,
	input: { userId: string; request: MarkNotificationsReadRequest },
): Promise<void> {
	const now = deps.now();
	await markNotificationsRead(deps.db, {
		userId: input.userId,
		now,
		...("all" in input.request
			? { all: true as const }
			: { ids: input.request.ids }),
	});
}

export async function setGroupMuted(
	deps: AppDeps,
	input: { groupId: string; userId: string; muted: boolean },
): Promise<GroupMuteResponse> {
	return deps.db.transaction(async (executor) => {
		await getGroupAccess(executor, {
			groupId: input.groupId,
			userId: input.userId,
			minimumRole: "viewer",
		});
		await updateGroupUserMuted(executor, input);
		return GroupMuteResponse.parse({ muted: input.muted });
	});
}

export async function getMyNotificationSettings(
	deps: AppDeps,
	userId: string,
): Promise<NotificationSettingsDto> {
	const row = await getNotificationSettings(deps.db, userId);
	return NotificationSettingsDto.parse({
		emailImmediate: row.emailImmediate,
		emailDigest: row.emailDigest,
	});
}

export async function updateMyNotificationSettings(
	deps: AppDeps,
	input: { userId: string; request: UpdateNotificationSettingsRequest },
): Promise<NotificationSettingsDto> {
	const row = await upsertNotificationSettings(deps.db, {
		userId: input.userId,
		...(input.request.emailImmediate !== undefined
			? { emailImmediate: input.request.emailImmediate }
			: {}),
		...(input.request.emailDigest !== undefined
			? { emailDigest: input.request.emailDigest }
			: {}),
	});
	return NotificationSettingsDto.parse({
		emailImmediate: row.emailImmediate,
		emailDigest: row.emailDigest,
	});
}

export async function unsubscribeNotifications(
	deps: AppDeps,
	token: string,
): Promise<void> {
	const tokenHash = createHash("sha256").update(token).digest("hex");
	const updated = await unsubscribeByTokenHash(deps.db, tokenHash);
	if (!updated) throw new AppError(404, "NOT_FOUND", "Resource not found");
}
