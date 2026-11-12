import { asc, eq, inArray } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { members } from "./schema-groups.js";
export const MEMBER_COLUMNS = {
	id: members.id,
	groupId: members.groupId,
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
