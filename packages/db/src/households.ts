import { and, asc, eq, inArray, isNotNull, ne, sql } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { members } from "./schema-groups.js";
import { households } from "./schema-households.js";

export type HouseholdRow = {
	id: string;
	groupId: string;
	name: string;
	representativeMemberId: string;
	memberIds: string[];
	createdAt: Date;
	updatedAt: Date;
};

const HOUSEHOLD_COLUMNS = {
	id: households.id,
	groupId: households.groupId,
	name: households.name,
	representativeMemberId: households.representativeMemberId,
	createdAt: households.createdAt,
	updatedAt: households.updatedAt,
};

function attachMembersToHouseholds(
	rows: Array<Omit<HouseholdRow, "memberIds">>,
	memberRows: Array<{
		id: string;
		groupId: string;
		householdId: string | null;
	}>,
): HouseholdRow[] {
	const membersByHousehold = new Map<string, string[]>();
	for (const member of memberRows) {
		if (member.householdId === null) continue;
		const existing = membersByHousehold.get(member.householdId);
		if (existing) {
			existing.push(member.id);
		} else {
			membersByHousehold.set(member.householdId, [member.id]);
		}
	}
	return rows.map((row) => ({
		...row,
		memberIds: membersByHousehold.get(row.id) ?? [],
	}));
}

export async function listGroupHouseholds(
	executor: DbExecutor,
	groupId: string,
): Promise<HouseholdRow[]> {
	const [rows, memberRows] = await Promise.all([
		executor
			.select(HOUSEHOLD_COLUMNS)
			.from(households)
			.where(eq(households.groupId, groupId))
			.orderBy(asc(households.createdAt), asc(households.id)),
		executor
			.select({
				id: members.id,
				groupId: members.groupId,
				householdId: members.householdId,
			})
			.from(members)
			.where(and(eq(members.groupId, groupId), isNotNull(members.householdId)))
			.orderBy(asc(members.position)),
	]);
	return attachMembersToHouseholds(rows, memberRows);
}

export async function listHouseholdsForGroups(
	executor: DbExecutor,
	groupIds: string[],
): Promise<HouseholdRow[]> {
	if (groupIds.length === 0) return [];
	const [rows, memberRows] = await Promise.all([
		executor
			.select(HOUSEHOLD_COLUMNS)
			.from(households)
			.where(inArray(households.groupId, groupIds))
			.orderBy(asc(households.createdAt), asc(households.id)),
		executor
			.select({
				id: members.id,
				groupId: members.groupId,
				householdId: members.householdId,
			})
			.from(members)
			.where(
				and(inArray(members.groupId, groupIds), isNotNull(members.householdId)),
			)
			.orderBy(asc(members.position)),
	]);
	return attachMembersToHouseholds(rows, memberRows);
}

export async function findHousehold(
	executor: DbExecutor,
	groupId: string,
	householdId: string,
): Promise<HouseholdRow | null> {
	const [row] = await executor
		.select(HOUSEHOLD_COLUMNS)
		.from(households)
		.where(and(eq(households.groupId, groupId), eq(households.id, householdId)))
		.limit(1);
	if (!row) return null;
	const memberRows = await executor
		.select({
			id: members.id,
			groupId: members.groupId,
			householdId: members.householdId,
		})
		.from(members)
		.where(
			and(eq(members.groupId, groupId), eq(members.householdId, householdId)),
		)
		.orderBy(asc(members.position));
	return attachMembersToHouseholds([row], memberRows)[0] ?? null;
}

export async function findHouseholdByRepresentative(
	executor: DbExecutor,
	groupId: string,
	representativeMemberId: string,
) {
	const [row] = await executor
		.select({ id: households.id, name: households.name })
		.from(households)
		.where(
			and(
				eq(households.groupId, groupId),
				eq(households.representativeMemberId, representativeMemberId),
			),
		)
		.limit(1);
	return row ?? null;
}

export async function countGroupHouseholds(
	executor: DbExecutor,
	groupId: string,
): Promise<number> {
	const [row] = await executor
		.select({ count: sql<number>`count(*)::int` })
		.from(households)
		.where(eq(households.groupId, groupId));
	return row?.count ?? 0;
}

export async function insertHousehold(
	executor: DbExecutor,
	input: {
		groupId: string;
		name: string;
		representativeMemberId: string;
		now: Date;
	},
) {
	const [row] = await executor
		.insert(households)
		.values({
			groupId: input.groupId,
			name: input.name,
			representativeMemberId: input.representativeMemberId,
			createdAt: input.now,
			updatedAt: input.now,
		})
		.returning(HOUSEHOLD_COLUMNS);
	if (!row) throw new Error("Household insert failed");
	return row;
}

export async function updateHousehold(
	executor: DbExecutor,
	input: {
		groupId: string;
		householdId: string;
		changes: {
			name?: string;
			representativeMemberId?: string;
			updatedAt: Date;
		};
	},
) {
	const [row] = await executor
		.update(households)
		.set(input.changes)
		.where(
			and(
				eq(households.groupId, input.groupId),
				eq(households.id, input.householdId),
			),
		)
		.returning(HOUSEHOLD_COLUMNS);
	return row ?? null;
}

export function deleteHousehold(
	executor: DbExecutor,
	groupId: string,
	householdId: string,
) {
	return executor
		.delete(households)
		.where(
			and(eq(households.groupId, groupId), eq(households.id, householdId)),
		);
}

export async function setHouseholdMembers(
	executor: DbExecutor,
	input: {
		groupId: string;
		householdId: string;
		memberIds: string[];
		now: Date;
	},
) {
	await executor
		.update(members)
		.set({ householdId: null, updatedAt: input.now })
		.where(
			and(
				eq(members.groupId, input.groupId),
				eq(members.householdId, input.householdId),
				ne(members.kind, "fund"),
			),
		);
	if (input.memberIds.length === 0) return;
	await executor
		.update(members)
		.set({ householdId: input.householdId, updatedAt: input.now })
		.where(
			and(
				eq(members.groupId, input.groupId),
				inArray(members.id, input.memberIds),
			),
		);
}
