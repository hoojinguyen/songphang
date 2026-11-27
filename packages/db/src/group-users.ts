import { and, asc, desc, eq, inArray, sql } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { users } from "./schema.js";
import { groupUsers } from "./schema-groups.js";
export function listGroupUsers(executor: DbExecutor, groupId: string) {
	return executor
		.select({
			userId: groupUsers.userId,
			name: users.name,
			role: groupUsers.role,
			memberId: groupUsers.memberId,
		})
		.from(groupUsers)
		.innerJoin(users, eq(users.id, groupUsers.userId))
		.where(eq(groupUsers.groupId, groupId))
		.orderBy(
			desc(sql`${groupUsers.role} = 'owner'`),
			asc(groupUsers.createdAt),
			asc(groupUsers.userId),
		);
}
export function listGroupUsersForGroups(
	executor: DbExecutor,
	groupIds: string[],
) {
	if (groupIds.length === 0) return Promise.resolve([]);
	return executor
		.select({
			groupId: groupUsers.groupId,
			userId: groupUsers.userId,
			role: groupUsers.role,
			memberId: groupUsers.memberId,
		})
		.from(groupUsers)
		.where(inArray(groupUsers.groupId, groupIds));
}
export function updateGroupUserRole(
	executor: DbExecutor,
	input: {
		groupId: string;
		userId: string;
		role: "owner" | "editor" | "viewer";
	},
) {
	return executor
		.update(groupUsers)
		.set({ role: input.role })
		.where(
			and(
				eq(groupUsers.groupId, input.groupId),
				eq(groupUsers.userId, input.userId),
			),
		);
}
export function updateGroupUserMuted(
	executor: DbExecutor,
	input: {
		groupId: string;
		userId: string;
		muted: boolean;
	},
) {
	return executor
		.update(groupUsers)
		.set({ muted: input.muted })
		.where(
			and(
				eq(groupUsers.groupId, input.groupId),
				eq(groupUsers.userId, input.userId),
			),
		);
}
export function deleteGroupUser(
	executor: DbExecutor,
	input: { groupId: string; userId: string },
) {
	return executor
		.delete(groupUsers)
		.where(
			and(
				eq(groupUsers.groupId, input.groupId),
				eq(groupUsers.userId, input.userId),
			),
		);
}
