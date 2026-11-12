import { and, desc, eq, inArray, isNull, lt, or } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { users } from "./schema.js";
import { members } from "./schema-groups.js";
import {
	transactionPayers,
	transactionShares,
	transactions,
} from "./schema-transactions.js";
export const TRANSACTION_COLUMNS = {
	id: transactions.id,
	groupId: transactions.groupId,
	type: transactions.type,
	description: transactions.description,
	amount: transactions.amount,
	currency: transactions.currency,
	occurredAt: transactions.occurredAt,
	category: transactions.category,
	split: transactions.splitInput,
	version: transactions.version,
	createdAt: transactions.createdAt,
	updatedAt: transactions.updatedAt,
	deletedAt: transactions.deletedAt,
	createdBy: { id: users.id, name: users.name },
};
export type TransactionCursor = { occurredAt: string; id: string };
export function listTransactionRows(
	executor: DbExecutor,
	input: { groupId: string; limit: number; cursor: TransactionCursor | null },
) {
	const cursor = input.cursor;
	return executor
		.select(TRANSACTION_COLUMNS)
		.from(transactions)
		.leftJoin(users, eq(users.id, transactions.createdBy))
		.where(
			and(
				eq(transactions.groupId, input.groupId),
				isNull(transactions.deletedAt),
				cursor === null
					? undefined
					: or(
							lt(transactions.occurredAt, new Date(cursor.occurredAt)),
							and(
								eq(transactions.occurredAt, new Date(cursor.occurredAt)),
								lt(transactions.id, cursor.id),
							),
						),
			),
		)
		.orderBy(desc(transactions.occurredAt), desc(transactions.id))
		.limit(input.limit);
}
export async function findTransactionRow(
	executor: DbExecutor,
	groupId: string,
	transactionId: string,
) {
	const [row] = await executor
		.select(TRANSACTION_COLUMNS)
		.from(transactions)
		.leftJoin(users, eq(users.id, transactions.createdBy))
		.where(
			and(
				eq(transactions.groupId, groupId),
				eq(transactions.id, transactionId),
			),
		)
		.limit(1);
	return row ?? null;
}
export function listTransactionPayers(
	executor: DbExecutor,
	groupId: string,
	transactionIds: string[],
) {
	if (transactionIds.length === 0) return Promise.resolve([]);
	return executor
		.select({
			transactionId: transactionPayers.transactionId,
			memberId: transactionPayers.memberId,
			amount: transactionPayers.amount,
		})
		.from(transactionPayers)
		.innerJoin(
			transactions,
			eq(transactions.id, transactionPayers.transactionId),
		)
		.innerJoin(members, eq(members.id, transactionPayers.memberId))
		.where(
			and(
				eq(transactions.groupId, groupId),
				inArray(transactions.id, transactionIds),
			),
		)
		.orderBy(members.position);
}
export function listTransactionShares(
	executor: DbExecutor,
	groupId: string,
	transactionIds: string[],
) {
	if (transactionIds.length === 0) return Promise.resolve([]);
	return executor
		.select({
			transactionId: transactionShares.transactionId,
			memberId: transactionShares.memberId,
			amount: transactionShares.amount,
		})
		.from(transactionShares)
		.innerJoin(
			transactions,
			eq(transactions.id, transactionShares.transactionId),
		)
		.innerJoin(members, eq(members.id, transactionShares.memberId))
		.where(
			and(
				eq(transactions.groupId, groupId),
				inArray(transactions.id, transactionIds),
			),
		)
		.orderBy(members.position);
}
export async function insertTransaction(
	executor: DbExecutor,
	input: typeof transactions.$inferInsert,
) {
	const [row] = await executor
		.insert(transactions)
		.values(input)
		.returning({ id: transactions.id });
	if (row === undefined) throw new Error("Transaction insert failed");
	return row;
}
export function insertTransactionPayers(
	executor: DbExecutor,
	rows: Array<typeof transactionPayers.$inferInsert>,
) {
	return executor.insert(transactionPayers).values(rows);
}
export function insertTransactionShares(
	executor: DbExecutor,
	rows: Array<typeof transactionShares.$inferInsert>,
) {
	return executor.insert(transactionShares).values(rows);
}
