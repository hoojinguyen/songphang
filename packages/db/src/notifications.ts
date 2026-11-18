import {
	and,
	count,
	desc,
	eq,
	inArray,
	isNotNull,
	isNull,
	lt,
	or,
	type SQL,
} from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { comments } from "./schema-comments.js";
import { groupUsers } from "./schema-groups.js";
import { notifications } from "./schema-notifications.js";

export type NotificationRow = typeof notifications.$inferSelect;
export type NotificationCursor = { createdAt: string; id: string };

export async function resolveNotificationRecipients(
	executor: DbExecutor,
	input: {
		groupId: string;
		actorUserId: string | null;
		userIds?: string[];
		memberIds?: string[];
	},
): Promise<string[]> {
	const uniqueUsers = [...new Set(input.userIds ?? [])].filter(
		(id) => id !== input.actorUserId,
	);
	const uniqueMembers = [...new Set(input.memberIds ?? [])];
	const conditions: SQL[] = [];
	if (uniqueUsers.length > 0)
		conditions.push(inArray(groupUsers.userId, uniqueUsers));
	if (uniqueMembers.length > 0)
		conditions.push(inArray(groupUsers.memberId, uniqueMembers));
	if (conditions.length === 0) return [];
	const rows = await executor
		.select({ userId: groupUsers.userId })
		.from(groupUsers)
		.where(
			and(
				eq(groupUsers.groupId, input.groupId),
				eq(groupUsers.muted, false),
				conditions.length === 1 ? conditions[0] : or(...conditions),
			),
		);
	const resolved = new Set<string>();
	for (const row of rows) {
		if (row.userId !== input.actorUserId) resolved.add(row.userId);
	}
	return [...resolved];
}

export async function insertNotificationRows(
	executor: DbExecutor,
	rows: Array<{
		userId: string;
		groupId: string;
		kind: string;
		payload: unknown;
		createdAt: Date;
	}>,
): Promise<Array<{ id: string; userId: string }>> {
	if (rows.length === 0) return [];
	return executor
		.insert(notifications)
		.values(rows)
		.returning({ id: notifications.id, userId: notifications.userId });
}

export function listUserNotifications(
	executor: DbExecutor,
	input: {
		userId: string;
		limit: number;
		cursor: NotificationCursor | null;
	},
): Promise<NotificationRow[]> {
	const cursor = input.cursor;
	return executor
		.select({
			id: notifications.id,
			userId: notifications.userId,
			groupId: notifications.groupId,
			kind: notifications.kind,
			payload: notifications.payload,
			readAt: notifications.readAt,
			createdAt: notifications.createdAt,
		})
		.from(notifications)
		.innerJoin(
			groupUsers,
			and(
				eq(groupUsers.groupId, notifications.groupId),
				eq(groupUsers.userId, notifications.userId),
			),
		)
		.where(
			and(
				eq(notifications.userId, input.userId),
				cursor === null
					? undefined
					: or(
							lt(notifications.createdAt, new Date(cursor.createdAt)),
							and(
								eq(notifications.createdAt, new Date(cursor.createdAt)),
								lt(notifications.id, cursor.id),
							),
						),
			),
		)
		.orderBy(desc(notifications.createdAt), desc(notifications.id))
		.limit(input.limit);
}

export async function countUnreadNotifications(
	executor: DbExecutor,
	userId: string,
): Promise<number> {
	const [row] = await executor
		.select({ total: count() })
		.from(notifications)
		.innerJoin(
			groupUsers,
			and(
				eq(groupUsers.groupId, notifications.groupId),
				eq(groupUsers.userId, notifications.userId),
			),
		)
		.where(and(eq(notifications.userId, userId), isNull(notifications.readAt)));
	return Number(row?.total ?? 0);
}

export async function markNotificationsRead(
	executor: DbExecutor,
	input:
		| { userId: string; now: Date; ids: string[] }
		| { userId: string; now: Date; all: true },
): Promise<void> {
	if ("ids" in input && input.ids.length === 0) return;
	await executor
		.update(notifications)
		.set({ readAt: input.now })
		.where(
			and(
				eq(notifications.userId, input.userId),
				isNull(notifications.readAt),
				"ids" in input ? inArray(notifications.id, input.ids) : undefined,
			),
		);
}

export async function findGroupOwnerUserId(
	executor: DbExecutor,
	groupId: string,
): Promise<string | null> {
	const [row] = await executor
		.select({ userId: groupUsers.userId })
		.from(groupUsers)
		.where(and(eq(groupUsers.groupId, groupId), eq(groupUsers.role, "owner")))
		.limit(1);
	return row?.userId ?? null;
}

export async function listCommenterUserIds(
	executor: DbExecutor,
	input: { groupId: string; transactionId: string },
): Promise<string[]> {
	const rows = await executor
		.selectDistinct({ userId: comments.authorUserId })
		.from(comments)
		.where(
			and(
				eq(comments.groupId, input.groupId),
				eq(comments.transactionId, input.transactionId),
				isNull(comments.deletedAt),
				isNotNull(comments.authorUserId),
			),
		);
	return rows.flatMap((row) => (row.userId ? [row.userId] : []));
}
