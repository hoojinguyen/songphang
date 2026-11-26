import { and, asc, eq } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { transactions } from "./schema-transactions.js";
import { countedTransaction } from "./transactions.js";

export function listCountedTransactionsForBreakdown(
	executor: DbExecutor,
	groupId: string,
) {
	return executor
		.select({
			id: transactions.id,
			type: transactions.type,
			description: transactions.description,
			amount: transactions.amount,
			occurredAt: transactions.occurredAt,
			cycleId: transactions.cycleId,
		})
		.from(transactions)
		.where(
			and(
				eq(transactions.groupId, groupId),
				countedTransaction("transactions"),
			),
		)
		.orderBy(asc(transactions.occurredAt), asc(transactions.id));
}
