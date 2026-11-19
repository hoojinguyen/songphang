import {
	and,
	asc,
	count,
	desc,
	eq,
	gt,
	inArray,
	isNotNull,
	isNull,
	lt,
	lte,
	or,
	type SQL,
	sql,
} from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { users } from "./schema.js";
import { comments } from "./schema-comments.js";
import { groupUsers } from "./schema-groups.js";
import {
	jobCheckpoints,
	notificationSettings,
	notifications,
	notificationUnsubscribeTokens,
} from "./schema-notifications.js";

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

const DIGEST_KINDS = [
	"expense_added",
	"expense_changed",
	"comment_added",
	"budget_state",
];

export async function getNotificationSettings(
	executor: DbExecutor,
	userId: string,
): Promise<{
	emailImmediate: boolean;
	emailDigest: boolean;
	unsubscribeTokenHash: string | null;
}> {
	const [row] = await executor
		.select({
			emailImmediate: notificationSettings.emailImmediate,
			emailDigest: notificationSettings.emailDigest,
			unsubscribeTokenHash: notificationSettings.unsubscribeTokenHash,
		})
		.from(notificationSettings)
		.where(eq(notificationSettings.userId, userId))
		.limit(1);
	return (
		row ?? {
			emailImmediate: true,
			emailDigest: true,
			unsubscribeTokenHash: null,
		}
	);
}

export async function upsertNotificationSettings(
	executor: DbExecutor,
	input: {
		userId: string;
		emailImmediate?: boolean;
		emailDigest?: boolean;
		unsubscribeTokenHash?: string;
	},
): Promise<{
	emailImmediate: boolean;
	emailDigest: boolean;
	unsubscribeTokenHash: string | null;
}> {
	const updateSet: {
		emailImmediate?: boolean;
		emailDigest?: boolean;
		unsubscribeTokenHash?: string;
	} = {};
	if (input.emailImmediate !== undefined)
		updateSet.emailImmediate = input.emailImmediate;
	if (input.emailDigest !== undefined)
		updateSet.emailDigest = input.emailDigest;
	if (input.unsubscribeTokenHash !== undefined)
		updateSet.unsubscribeTokenHash = input.unsubscribeTokenHash;
	const [row] = await executor
		.insert(notificationSettings)
		.values({
			userId: input.userId,
			emailImmediate: input.emailImmediate ?? true,
			emailDigest: input.emailDigest ?? true,
			unsubscribeTokenHash: input.unsubscribeTokenHash ?? null,
		})
		.onConflictDoUpdate({
			target: notificationSettings.userId,
			set:
				Object.keys(updateSet).length > 0
					? updateSet
					: { userId: input.userId },
		})
		.returning({
			emailImmediate: notificationSettings.emailImmediate,
			emailDigest: notificationSettings.emailDigest,
			unsubscribeTokenHash: notificationSettings.unsubscribeTokenHash,
		});
	if (row === undefined) throw new Error("Notification settings upsert failed");
	return row;
}

export async function insertUnsubscribeTokenHash(
	executor: DbExecutor,
	input: { userId: string; tokenHash: string; now?: Date },
): Promise<void> {
	await executor.insert(notificationUnsubscribeTokens).values({
		userId: input.userId,
		tokenHash: input.tokenHash,
		...(input.now ? { createdAt: input.now } : {}),
	});
	await executor
		.insert(notificationSettings)
		.values({ userId: input.userId })
		.onConflictDoNothing();
}

export async function unsubscribeByTokenHash(
	executor: DbExecutor,
	tokenHash: string,
): Promise<boolean> {
	const [issued] = await executor
		.select({ userId: notificationUnsubscribeTokens.userId })
		.from(notificationUnsubscribeTokens)
		.where(eq(notificationUnsubscribeTokens.tokenHash, tokenHash))
		.limit(1);
	let userId = issued?.userId ?? null;
	if (userId === null) {
		const [legacy] = await executor
			.select({ userId: notificationSettings.userId })
			.from(notificationSettings)
			.where(eq(notificationSettings.unsubscribeTokenHash, tokenHash))
			.limit(1);
		userId = legacy?.userId ?? null;
	}
	if (userId === null) return false;
	await upsertNotificationSettings(executor, {
		userId,
		emailImmediate: false,
		emailDigest: false,
	});
	return true;
}

export async function findNotificationForImmediateMail(
	executor: DbExecutor,
	notificationId: string,
) {
	const [row] = await executor
		.select({
			id: notifications.id,
			userId: notifications.userId,
			groupId: notifications.groupId,
			kind: notifications.kind,
			payload: notifications.payload,
			readAt: notifications.readAt,
			email: users.email,
			emailVerifiedAt: users.emailVerifiedAt,
			emailImmediate: notificationSettings.emailImmediate,
			unsubscribeTokenHash: notificationSettings.unsubscribeTokenHash,
			memberUserId: groupUsers.userId,
		})
		.from(notifications)
		.innerJoin(users, eq(users.id, notifications.userId))
		.leftJoin(
			groupUsers,
			and(
				eq(groupUsers.groupId, notifications.groupId),
				eq(groupUsers.userId, notifications.userId),
			),
		)
		.leftJoin(
			notificationSettings,
			eq(notificationSettings.userId, notifications.userId),
		)
		.where(eq(notifications.id, notificationId))
		.limit(1);
	if (!row) return null;
	return {
		id: row.id,
		userId: row.userId,
		groupId: row.groupId,
		kind: row.kind,
		payload: row.payload,
		readAt: row.readAt,
		email: row.email,
		emailVerifiedAt: row.emailVerifiedAt,
		emailImmediate: row.emailImmediate ?? true,
		unsubscribeTokenHash: row.unsubscribeTokenHash ?? null,
		inGroup: row.memberUserId !== null,
	};
}

export function listUnreadDigestNotifications(
	executor: DbExecutor,
	input: { since: Date | null; until: Date },
) {
	return executor
		.select({
			id: notifications.id,
			userId: notifications.userId,
			groupId: notifications.groupId,
			kind: notifications.kind,
			payload: notifications.payload,
			createdAt: notifications.createdAt,
			email: users.email,
			unsubscribeTokenHash: notificationSettings.unsubscribeTokenHash,
		})
		.from(notifications)
		.innerJoin(users, eq(users.id, notifications.userId))
		.innerJoin(
			groupUsers,
			and(
				eq(groupUsers.groupId, notifications.groupId),
				eq(groupUsers.userId, notifications.userId),
			),
		)
		.leftJoin(
			notificationSettings,
			eq(notificationSettings.userId, notifications.userId),
		)
		.where(
			and(
				isNull(notifications.readAt),
				inArray(notifications.kind, DIGEST_KINDS),
				isNotNull(users.emailVerifiedAt),
				sql`coalesce(${notificationSettings.emailDigest}, true) = true`,
				lte(notifications.createdAt, input.until),
				input.since ? gt(notifications.createdAt, input.since) : undefined,
			),
		)
		.orderBy(
			asc(notifications.userId),
			asc(notifications.groupId),
			asc(notifications.createdAt),
			asc(notifications.id),
		);
}

export async function getJobCheckpoint(
	executor: DbExecutor,
	name: string,
): Promise<Date | null> {
	const [row] = await executor
		.select({ lastRunAt: jobCheckpoints.lastRunAt })
		.from(jobCheckpoints)
		.where(eq(jobCheckpoints.name, name))
		.limit(1);
	return row?.lastRunAt ?? null;
}

export async function setJobCheckpoint(
	executor: DbExecutor,
	input: { name: string; lastRunAt: Date },
): Promise<void> {
	await executor
		.insert(jobCheckpoints)
		.values({ name: input.name, lastRunAt: input.lastRunAt })
		.onConflictDoUpdate({
			target: jobCheckpoints.name,
			set: { lastRunAt: input.lastRunAt },
		});
}

export async function deleteOldNotifications(
	executor: DbExecutor,
	cutoff: Date,
): Promise<number> {
	const rows = await executor
		.delete(notifications)
		.where(lt(notifications.createdAt, cutoff))
		.returning({ id: notifications.id });
	return rows.length;
}
