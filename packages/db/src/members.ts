import { and, asc, eq, inArray, sql } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { groupUsers, members } from "./schema-groups.js";
import { transactionPayers, transactionShares } from "./schema-transactions.js";
export const MEMBER_COLUMNS = {
	id: members.id,
	claimed: sql<boolean>`exists(select 1 from ${groupUsers} where ${groupUsers.groupId} = ${members.groupId} and ${groupUsers.memberId} = ${members.id})`,
	groupId: members.groupId,
	kind: members.kind,
	fundHolderMemberId: members.fundHolderMemberId,
	name: members.name,
	active: members.active,
	defaultWeight: members.defaultWeight,
	position: members.position,
	shape: members.shape,
	color: members.color,
};
export function listGroupMembers(executor: DbExecutor, groupId: string) {
	return executor
		.select(MEMBER_COLUMNS)
		.from(members)
		.where(eq(members.groupId, groupId))
		.orderBy(asc(members.position));
}
export function listPeople(executor: DbExecutor, groupId: string) {
	return executor
		.select(MEMBER_COLUMNS)
		.from(members)
		.where(and(eq(members.groupId, groupId), eq(members.kind, "person")))
		.orderBy(asc(members.position));
}
export async function findFund(executor: DbExecutor, groupId: string) {
	const [fund] = await executor
		.select(MEMBER_COLUMNS)
		.from(members)
		.where(and(eq(members.groupId, groupId), eq(members.kind, "fund")))
		.limit(1);
	return fund ?? null;
}
export function listMembersForGroups(executor: DbExecutor, groupIds: string[]) {
	if (groupIds.length === 0) return Promise.resolve([]);
	return executor
		.select(MEMBER_COLUMNS)
		.from(members)
		.where(inArray(members.groupId, groupIds))
		.orderBy(asc(members.position));
}
export async function insertMember(
	executor: DbExecutor,
	input: typeof members.$inferInsert,
) {
	const [member] = await executor
		.insert(members)
		.values(input)
		.returning(MEMBER_COLUMNS);
	if (member === undefined) throw new Error("Member insert failed");
	return member;
}

export async function findMember(
	executor: DbExecutor,
	groupId: string,
	memberId: string,
) {
	const [member] = await executor
		.select(MEMBER_COLUMNS)
		.from(members)
		.where(and(eq(members.groupId, groupId), eq(members.id, memberId)))
		.limit(1);
	return member ?? null;
}
export function updateMember(
	executor: DbExecutor,
	input: {
		groupId: string;
		memberId: string;
		changes: {
			name?: string;
			defaultWeight?: string;
			active?: boolean;
			updatedAt: Date;
		};
	},
) {
	return executor
		.update(members)
		.set(input.changes)
		.where(
			and(eq(members.groupId, input.groupId), eq(members.id, input.memberId)),
		);
}
export function deleteMember(
	executor: DbExecutor,
	groupId: string,
	memberId: string,
) {
	return executor
		.delete(members)
		.where(and(eq(members.groupId, groupId), eq(members.id, memberId)));
}
export async function hasMemberTransactions(
	executor: DbExecutor,
	groupId: string,
	memberId: string,
) {
	const [row] = await executor
		.select({
			hasTransactions: sql<boolean>`exists(select 1 from ${transactionPayers} where ${transactionPayers.memberId} = ${members.id}) or exists(select 1 from ${transactionShares} where ${transactionShares.memberId} = ${members.id})`,
		})
		.from(members)
		.where(and(eq(members.groupId, groupId), eq(members.id, memberId)));
	return row?.hasTransactions ?? false;
}
