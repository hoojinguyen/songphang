import { eq, sql } from "drizzle-orm";
import { z } from "zod";
import type { DbExecutor } from "./client.js";
import { budgets } from "./schema-budgets.js";
import { countedTransaction } from "./transactions.js";

const SpentRowSchema = z.object({ spent: z.string() });

export async function findBudget(executor: DbExecutor, groupId: string) {
	const [row] = await executor
		.select()
		.from(budgets)
		.where(eq(budgets.groupId, groupId))
		.limit(1);
	return row ?? null;
}

export async function upsertBudget(
	executor: DbExecutor,
	input: {
		groupId: string;
		period: "month" | "total";
		amount: number;
		updatedBy: string;
		now: Date;
	},
) {
	const [row] = await executor
		.insert(budgets)
		.values({
			groupId: input.groupId,
			period: input.period,
			amount: input.amount,
			updatedBy: input.updatedBy,
			createdAt: input.now,
			updatedAt: input.now,
		})
		.onConflictDoUpdate({
			target: budgets.groupId,
			set: {
				period: input.period,
				amount: input.amount,
				updatedBy: input.updatedBy,
				updatedAt: input.now,
			},
		})
		.returning();
	if (row === undefined) throw new Error("Budget upsert failed");
	return row;
}

export function deleteBudget(executor: DbExecutor, groupId: string) {
	return executor.delete(budgets).where(eq(budgets.groupId, groupId));
}

export async function sumSpent(
	executor: DbExecutor,
	groupId: string,
	range: { start?: Date; endExclusive?: Date },
): Promise<number> {
	const startFilter =
		range.start === undefined
			? sql``
			: sql`and t.occurred_at >= ${range.start.toISOString()}::timestamptz`;
	const endFilter =
		range.endExclusive === undefined
			? sql``
			: sql`and t.occurred_at < ${range.endExclusive.toISOString()}::timestamptz`;
	const rows = await executor.execute(sql`
		select coalesce(
			sum(case when t.type = 'income' then -t.amount else t.amount end),
			0
		)::bigint::text as spent
		from transactions t
		where t.group_id = ${groupId}::uuid
			and ${countedTransaction("t")}
			and t.type in ('expense', 'income')
			${startFilter}
			${endFilter}
	`);
	return Number(SpentRowSchema.parse(rows[0] ?? { spent: "0" }).spent);
}
