import { and, count, eq, isNull } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { users } from "./schema.js";
import { groups, groupUsers } from "./schema-groups.js";
import { transactions } from "./schema-transactions.js";
export async function findInvite(executor: DbExecutor, token: string) {
	const [row] = await executor
		.select({
			id: groups.id,
			name: groups.name,
			active: groups.inviteActive,
			defaultRole: groups.defaultRole,
		})
		.from(groups)
		.where(eq(groups.inviteToken, token))
		.limit(1);
	return row ?? null;
}
export async function readGroupInvite(executor: DbExecutor, groupId: string) {
	const [row] = await executor
		.select({ token: groups.inviteToken, active: groups.inviteActive })
		.from(groups)
		.where(eq(groups.id, groupId))
		.limit(1);
	return row ?? null;
}
export function updateGroupInvite(
	executor: DbExecutor,
	input: { groupId: string; active?: boolean; token?: string; now: Date },
) {
	return executor
		.update(groups)
		.set({
			...(input.active === undefined ? {} : { inviteActive: input.active }),
			...(input.token === undefined ? {} : { inviteToken: input.token }),
			updatedAt: input.now,
		})
		.where(eq(groups.id, input.groupId));
}
export async function inviteGroupDetails(
	executor: DbExecutor,
	groupId: string,
) {
	const [owner] = await executor
		.select({ name: users.name })
		.from(groupUsers)
		.innerJoin(users, eq(users.id, groupUsers.userId))
		.where(and(eq(groupUsers.groupId, groupId), eq(groupUsers.role, "owner")))
		.limit(1);
	const [row] = await executor
		.select({ count: count() })
		.from(transactions)
		.where(
			and(eq(transactions.groupId, groupId), isNull(transactions.deletedAt)),
		);
	return { ownerName: owner?.name ?? "", transactionCount: row?.count ?? 0 };
}
export function setUserMember(
	executor: DbExecutor,
	input: { groupId: string; userId: string; memberId: string },
) {
	return executor
		.update(groupUsers)
		.set({ memberId: input.memberId })
		.where(
			and(
				eq(groupUsers.groupId, input.groupId),
				eq(groupUsers.userId, input.userId),
			),
		);
}
