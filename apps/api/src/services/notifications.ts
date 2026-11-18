import { z } from "@hono/zod-openapi";
import {
	GroupMuteResponse,
	type MarkNotificationsReadRequest,
	NotificationDto,
	type NotificationsListQuery,
	NotificationsListResponse,
	UnreadCountResponse,
} from "@songphang/contract";
import {
	countUnreadNotifications,
	listUserNotifications,
	markNotificationsRead,
	type NotificationCursor,
	type NotificationRow,
	updateGroupUserMuted,
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
