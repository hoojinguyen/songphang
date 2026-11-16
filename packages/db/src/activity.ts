import { and, desc, eq, lt, or, sql } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { users } from "./schema.js";
import { groupUsers } from "./schema-groups.js";
import { activityLog } from "./schema-records.js";
import { transactions } from "./schema-transactions.js";
export function insertActivity(
	executor: DbExecutor,
	input: typeof activityLog.$inferInsert,
) {
	return executor.insert(activityLog).values(input);
}

export function listActivityRows(
	executor: DbExecutor,
	input: {
		groupId: string;
		limit: number;
		cursor: { createdAt: string; id: string } | null;
	},
) {
	const cursor = input.cursor;
	return executor
		.select({
			id: activityLog.id,
			actorId: users.id,
			actorName: users.name,
			memberId: groupUsers.memberId,
			action: activityLog.action,
			entityType: activityLog.entityType,
			entityId: activityLog.entityId,
			summary: activityLog.summary,
			before: activityLog.before,
			after: activityLog.after,
			createdAt: activityLog.createdAt,
			canRestore: sql<boolean>`${activityLog.action} = 'delete' and ${activityLog.entityType} = 'transaction' and ${transactions.deletedAt} is not null`,
		})
		.from(activityLog)
		.leftJoin(users, eq(users.id, activityLog.actorUserId))
		.leftJoin(
			groupUsers,
			and(
				eq(groupUsers.groupId, activityLog.groupId),
				eq(groupUsers.userId, users.id),
			),
		)
		.leftJoin(
			transactions,
			and(
				eq(transactions.groupId, activityLog.groupId),
				eq(transactions.id, activityLog.entityId),
				eq(activityLog.entityType, "transaction"),
			),
		)
		.where(
			and(
				eq(activityLog.groupId, input.groupId),
				cursor
					? or(
							lt(activityLog.createdAt, new Date(cursor.createdAt)),
							and(
								eq(activityLog.createdAt, new Date(cursor.createdAt)),
								lt(activityLog.id, cursor.id),
							),
						)
					: undefined,
			),
		)
		.orderBy(desc(activityLog.createdAt), desc(activityLog.id))
		.limit(input.limit);
}
