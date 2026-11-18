import { and, desc, eq } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { groups, groupUsers } from "./schema-groups.js";
import { transactions } from "./schema-transactions.js";
import { deleteGroupSettlementRequests } from "./settlement-requests.js";

export async function findGroupAccess(
	executor: DbExecutor,
	groupId: string,
	userId: string,
) {
	const [access] = await executor
		.select({
			groupId: groupUsers.groupId,
			role: groupUsers.role,
			memberId: groupUsers.memberId,
			muted: groupUsers.muted,
		})
		.from(groupUsers)
		.where(and(eq(groupUsers.groupId, groupId), eq(groupUsers.userId, userId)))
		.limit(1);
	return access ?? null;
}
export async function findGroup(executor: DbExecutor, groupId: string) {
	const [group] = await executor
		.select({
			id: groups.id,
			name: groups.name,
			currency: groups.currency,
			minimizeDebts: groups.minimizeDebts,
			defaultRole: groups.defaultRole,
			reminderIntervalDays: groups.reminderIntervalDays,
			approvalThreshold: groups.approvalThreshold,
			createdAt: groups.createdAt,
		})
		.from(groups)
		.where(eq(groups.id, groupId))
		.limit(1);
	return group ?? null;
}
export function listUserGroups(executor: DbExecutor, userId: string) {
	return executor
		.select({
			id: groups.id,
			name: groups.name,
			currency: groups.currency,
			memberId: groupUsers.memberId,
		})
		.from(groups)
		.innerJoin(groupUsers, eq(groups.id, groupUsers.groupId))
		.where(eq(groupUsers.userId, userId))
		.orderBy(desc(groups.createdAt), desc(groups.id));
}
export async function insertGroup(
	executor: DbExecutor,
	input: typeof groups.$inferInsert,
) {
	const [group] = await executor
		.insert(groups)
		.values(input)
		.returning({ id: groups.id });
	if (group === undefined) throw new Error("Group insert failed");
	return group;
}
export function insertGroupUser(
	executor: DbExecutor,
	input: typeof groupUsers.$inferInsert,
) {
	return executor.insert(groupUsers).values(input);
}
export function updateGroup(
	executor: DbExecutor,
	input: {
		groupId: string;
		changes: {
			name?: string;
			minimizeDebts?: boolean;
			defaultRole?: "editor" | "viewer";
			reminderIntervalDays?: 3 | 7 | 14 | null;
			approvalThreshold?: number | null;
		};
		now: Date;
	},
) {
	return executor
		.update(groups)
		.set({ ...input.changes, updatedAt: input.now })
		.where(eq(groups.id, input.groupId));
}
export function lockGroup(executor: DbExecutor, groupId: string) {
	return executor
		.select({ id: groups.id })
		.from(groups)
		.where(eq(groups.id, groupId))
		.for("update");
}

export async function deleteGroupRow(executor: DbExecutor, groupId: string) {
	await deleteGroupSettlementRequests(executor, groupId);
	await executor.delete(transactions).where(eq(transactions.groupId, groupId));
	return executor.delete(groups).where(eq(groups.id, groupId));
}
