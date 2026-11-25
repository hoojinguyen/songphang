import { and, desc, eq, isNull, sql } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { users } from "./schema.js";
import { settlementCycles } from "./schema-cycles.js";
import { transactions } from "./schema-transactions.js";
import { countedTransaction } from "./transactions.js";

export type SettlementCycleRow = typeof settlementCycles.$inferSelect;

export function listSettlementCycles(executor: DbExecutor, groupId: string) {
	return executor
		.select({
			id: settlementCycles.id,
			groupId: settlementCycles.groupId,
			cycleNumber: settlementCycles.cycleNumber,
			title: settlementCycles.title,
			startedAt: settlementCycles.startedAt,
			closedAt: settlementCycles.closedAt,
			closedBy: settlementCycles.closedBy,
			closedByName: users.name,
			expenseCount: settlementCycles.expenseCount,
			totalExpenseAmount: settlementCycles.totalExpenseAmount,
			snapshot: settlementCycles.snapshot,
			createdAt: settlementCycles.createdAt,
		})
		.from(settlementCycles)
		.leftJoin(users, eq(users.id, settlementCycles.closedBy))
		.where(eq(settlementCycles.groupId, groupId))
		.orderBy(desc(settlementCycles.cycleNumber));
}

export async function findLatestSettlementCycle(
	executor: DbExecutor,
	groupId: string,
) {
	const [row] = await executor
		.select()
		.from(settlementCycles)
		.where(eq(settlementCycles.groupId, groupId))
		.orderBy(desc(settlementCycles.cycleNumber))
		.limit(1);
	return row ?? null;
}

export async function findSettlementCycle(
	executor: DbExecutor,
	groupId: string,
	cycleId: string,
) {
	const [row] = await executor
		.select()
		.from(settlementCycles)
		.where(
			and(
				eq(settlementCycles.groupId, groupId),
				eq(settlementCycles.id, cycleId),
			),
		)
		.limit(1);
	return row ?? null;
}

export async function insertSettlementCycle(
	executor: DbExecutor,
	input: typeof settlementCycles.$inferInsert,
): Promise<SettlementCycleRow> {
	const [row] = await executor
		.insert(settlementCycles)
		.values(input)
		.returning();
	if (!row) throw new Error("Settlement cycle insert failed");
	return row;
}

export function stampOpenCountedTransactionsToCycle(
	executor: DbExecutor,
	groupId: string,
	cycleId: string,
) {
	return executor
		.update(transactions)
		.set({ cycleId })
		.where(
			and(
				eq(transactions.groupId, groupId),
				isNull(transactions.cycleId),
				countedTransaction("transactions"),
			),
		);
}

export async function deleteSettlementCycle(
	executor: DbExecutor,
	groupId: string,
	cycleId: string,
) {
	const [row] = await executor
		.delete(settlementCycles)
		.where(
			and(
				eq(settlementCycles.groupId, groupId),
				eq(settlementCycles.id, cycleId),
			),
		)
		.returning({ id: settlementCycles.id });
	return row ?? null;
}

export async function countCurrentPeriodStats(
	executor: DbExecutor,
	groupId: string,
): Promise<{
	expenseCount: number;
	totalExpenseAmount: number;
	countedTransactionCount: number;
}> {
	const [row] = await executor
		.select({
			expenseCount: sql<number>`count(*) filter (where ${transactions.type} = 'expense')::int`,
			totalExpenseAmount: sql<string>`coalesce(sum(case when ${transactions.type} = 'expense' then ${transactions.amount} else 0 end), 0)::bigint::text`,
			countedTransactionCount: sql<number>`count(*)::int`,
		})
		.from(transactions)
		.where(
			and(
				eq(transactions.groupId, groupId),
				isNull(transactions.cycleId),
				countedTransaction("transactions"),
			),
		);
	return {
		expenseCount: row?.expenseCount ?? 0,
		totalExpenseAmount: Number(row?.totalExpenseAmount ?? "0"),
		countedTransactionCount: row?.countedTransactionCount ?? 0,
	};
}
