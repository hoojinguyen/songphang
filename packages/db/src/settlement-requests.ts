import { and, desc, eq, lt, sql } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { users } from "./schema.js";
import { settlementRequests } from "./schema-settlements.js";
export function listSettlementRequests(
	executor: DbExecutor,
	input: {
		groupId: string;
		status?: string | undefined;
		cursor?: string | undefined;
		limit: number;
	},
) {
	return executor
		.select({ request: settlementRequests, creatorName: users.name })
		.from(settlementRequests)
		.leftJoin(users, eq(users.id, settlementRequests.createdBy))
		.where(
			and(
				eq(settlementRequests.groupId, input.groupId),
				input.status === undefined
					? undefined
					: eq(settlementRequests.status, input.status),
				input.cursor === undefined
					? undefined
					: lt(settlementRequests.id, input.cursor),
			),
		)
		.orderBy(desc(settlementRequests.id))
		.limit(input.limit);
}
export async function findSettlementRequest(
	executor: DbExecutor,
	groupId: string,
	id: string,
) {
	const [row] = await executor
		.select()
		.from(settlementRequests)
		.where(
			and(
				eq(settlementRequests.groupId, groupId),
				eq(settlementRequests.id, id),
			),
		)
		.for("update");
	return row ?? null;
}
export async function insertSettlementRequest(
	executor: DbExecutor,
	input: typeof settlementRequests.$inferInsert,
) {
	const [row] = await executor
		.insert(settlementRequests)
		.values(input)
		.returning();
	if (!row) throw new Error("Settlement insert failed");
	return row;
}
export async function resolveSettlementRequest(
	executor: DbExecutor,
	input: {
		groupId: string;
		id: string;
		status: string;
		userId: string;
		now: Date;
		transactionId: string | null;
	},
) {
	const [row] = await executor
		.update(settlementRequests)
		.set({
			status: input.status,
			resolvedBy: input.userId,
			resolvedAt: input.now,
			transactionId: input.transactionId,
		})
		.where(
			and(
				eq(settlementRequests.groupId, input.groupId),
				eq(settlementRequests.id, input.id),
				eq(settlementRequests.status, "pending"),
			),
		)
		.returning();
	if (!row) throw new Error("Settlement resolution failed");
	return row;
}
export async function findPendingSettlement(
	executor: DbExecutor,
	input: { groupId: string; fromMemberId: string; toMemberId: string },
) {
	const [row] = await executor
		.select()
		.from(settlementRequests)
		.where(
			and(
				eq(settlementRequests.groupId, input.groupId),
				eq(settlementRequests.fromMemberId, input.fromMemberId),
				eq(settlementRequests.toMemberId, input.toMemberId),
				eq(settlementRequests.status, "pending"),
			),
		);
	return row ?? null;
}
export async function hasMemberSettlementRequests(
	executor: DbExecutor,
	groupId: string,
	memberId: string,
) {
	const rows = await executor
		.select({ id: settlementRequests.id })
		.from(settlementRequests)
		.where(
			and(
				eq(settlementRequests.groupId, groupId),
				sql`(${settlementRequests.fromMemberId} = ${memberId} or ${settlementRequests.toMemberId} = ${memberId})`,
			),
		)
		.limit(1);
	return rows.length > 0;
}
export function deleteGroupSettlementRequests(
	executor: DbExecutor,
	groupId: string,
) {
	return executor
		.delete(settlementRequests)
		.where(eq(settlementRequests.groupId, groupId));
}

export function listPendingSettlements(executor: DbExecutor, groupId: string) {
	return executor
		.select()
		.from(settlementRequests)
		.where(
			and(
				eq(settlementRequests.groupId, groupId),
				eq(settlementRequests.status, "pending"),
			),
		);
}
