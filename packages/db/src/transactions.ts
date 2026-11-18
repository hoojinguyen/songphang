import {
	and,
	asc,
	desc,
	eq,
	exists,
	gte,
	inArray,
	isNull,
	lt,
	or,
	sql,
} from "drizzle-orm";
import { alias } from "drizzle-orm/pg-core";
import type { DbExecutor } from "./client.js";
import { users } from "./schema.js";
import { members } from "./schema-groups.js";
import {
	transactionPayers,
	transactionShares,
	transactions,
} from "./schema-transactions.js";

const editor = alias(users, "transaction_editor");
const approver = alias(users, "transaction_approver");
export function countedTransaction(aliasName: "t" | "transactions" = "t") {
	const table = sql.raw(aliasName);
	return sql`${table}.deleted_at is null and ${table}.approval_status in ('none', 'approved')`;
}
export const TRANSACTION_COLUMNS = {
	id: transactions.id,
	groupId: transactions.groupId,
	type: transactions.type,
	description: transactions.description,
	amount: transactions.amount,
	currency: transactions.currency,
	occurredAt: transactions.occurredAt,
	category: transactions.category,
	categoryId: transactions.categoryId,
	split: transactions.splitInput,
	version: transactions.version,
	approvalStatus: transactions.approvalStatus,
	approvalDecidedBy: transactions.approvalDecidedBy,
	approvalDecidedByName: approver.name,
	approvalDecidedAt: transactions.approvalDecidedAt,
	approvalNote: transactions.approvalNote,
	createdAt: transactions.createdAt,
	updatedAt: transactions.updatedAt,
	deletedAt: transactions.deletedAt,
	createdBy: { id: users.id, name: users.name },
	updatedBy: { id: editor.id, name: editor.name },
};
export type TransactionCursor = { occurredAt: string; id: string };
export type TransactionFilters = {
	searchPattern?: string;
	memberId?: string;
	category?: string;
	categoryId?: string;
	uncategorized?: boolean;
	spendingOnly?: boolean;
	type?: "expense" | "transfer" | "income";
	start?: Date;
	endExclusive?: Date;
};
export function listTransactionRows(
	executor: DbExecutor,
	input: {
		groupId: string;
		limit: number;
		cursor: TransactionCursor | null;
		filters?: TransactionFilters;
	},
) {
	const cursor = input.cursor;
	const filters = input.filters;
	const memberId = filters?.memberId;
	return executor
		.select(TRANSACTION_COLUMNS)
		.from(transactions)
		.leftJoin(users, eq(users.id, transactions.createdBy))
		.leftJoin(editor, eq(editor.id, transactions.updatedBy))
		.leftJoin(approver, eq(approver.id, transactions.approvalDecidedBy))
		.where(
			and(
				eq(transactions.groupId, input.groupId),
				isNull(transactions.deletedAt),
				filters?.searchPattern === undefined
					? undefined
					: sql`${transactions.descriptionSearch} like ${filters.searchPattern} escape '\\'`,
				memberId === undefined
					? undefined
					: or(
							exists(
								executor
									.select({ id: transactionPayers.transactionId })
									.from(transactionPayers)
									.where(
										and(
											eq(transactionPayers.transactionId, transactions.id),
											eq(transactionPayers.memberId, memberId),
										),
									),
							),
							exists(
								executor
									.select({ id: transactionShares.transactionId })
									.from(transactionShares)
									.where(
										and(
											eq(transactionShares.transactionId, transactions.id),
											eq(transactionShares.memberId, memberId),
										),
									),
							),
						),
				filters?.category === undefined
					? undefined
					: eq(transactions.category, filters.category),
				filters?.categoryId === undefined
					? undefined
					: eq(transactions.categoryId, filters.categoryId),
				filters?.uncategorized
					? and(isNull(transactions.category), isNull(transactions.categoryId))
					: undefined,
				filters?.type === undefined
					? undefined
					: eq(transactions.type, filters.type),
				filters?.spendingOnly
					? inArray(transactions.type, ["expense", "income"])
					: undefined,
				filters?.start === undefined
					? undefined
					: gte(transactions.occurredAt, filters.start),
				filters?.endExclusive === undefined
					? undefined
					: lt(transactions.occurredAt, filters.endExclusive),
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
		.leftJoin(editor, eq(editor.id, transactions.updatedBy))
		.leftJoin(approver, eq(approver.id, transactions.approvalDecidedBy))
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

export function listExportTransactions(executor: DbExecutor, groupId: string) {
	return executor
		.select({
			id: transactions.id,
			type: transactions.type,
			description: transactions.description,
			amount: transactions.amount,
			occurredAt: transactions.occurredAt,
			category: transactions.category,
			categoryId: transactions.categoryId,
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

export function listGroupLivePayers(executor: DbExecutor, groupId: string) {
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
				countedTransaction("transactions"),
			),
		)
		.orderBy(members.position);
}

export function listGroupLiveShares(executor: DbExecutor, groupId: string) {
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
		.where(
			and(
				eq(transactions.groupId, groupId),
				countedTransaction("transactions"),
			),
		);
}
