import { and, eq } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import {
	transactionPayers,
	transactionShares,
	transactions,
} from "./schema-transactions.js";
export async function lockTransaction(
	executor: DbExecutor,
	groupId: string,
	id: string,
) {
	const [row] = await executor
		.select({ id: transactions.id })
		.from(transactions)
		.where(and(eq(transactions.groupId, groupId), eq(transactions.id, id)))
		.for("update");
	return row ?? null;
}
export function updateTransactionRow(
	executor: DbExecutor,
	input: {
		groupId: string;
		id: string;
		changes: Partial<typeof transactions.$inferInsert>;
	},
) {
	return executor
		.update(transactions)
		.set(input.changes)
		.where(
			and(
				eq(transactions.groupId, input.groupId),
				eq(transactions.id, input.id),
			),
		);
}
export async function clearTransactionSides(executor: DbExecutor, id: string) {
	await executor
		.delete(transactionPayers)
		.where(eq(transactionPayers.transactionId, id));
	await executor
		.delete(transactionShares)
		.where(eq(transactionShares.transactionId, id));
}
