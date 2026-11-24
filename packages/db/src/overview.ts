import {
	and,
	asc,
	desc,
	eq,
	exists,
	inArray,
	isNotNull,
	isNull,
	lt,
	or,
	sql,
} from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { groupCategories } from "./schema-categories.js";
import { transactionDisputes } from "./schema-disputes.js";
import { groups, groupUsers, members } from "./schema-groups.js";
import {
	transactionPayers,
	transactionShares,
	transactions,
} from "./schema-transactions.js";
import type { TransactionCursor } from "./transactions.js";

export function listPersonalTransactionRows(
	executor: DbExecutor,
	input: {
		userId: string;
		limit: number;
		cursor: TransactionCursor | null;
		type?: "expense" | "transfer" | "income";
		groupId?: string;
		searchPattern?: string;
	},
) {
	const cursor = input.cursor;
	return executor
		.select({
			id: transactions.id,
			groupId: transactions.groupId,
			groupName: groups.name,
			groupArchivedAt: groups.archivedAt,
			callerMemberId: groupUsers.memberId,
			type: transactions.type,
			description: transactions.description,
			amount: transactions.amount,
			occurredAt: transactions.occurredAt,
			category: transactions.category,
			categoryName: groupCategories.name,
			approvalStatus: transactions.approvalStatus,
		})
		.from(transactions)
		.innerJoin(groups, eq(groups.id, transactions.groupId))
		.innerJoin(
			groupUsers,
			and(
				eq(groupUsers.groupId, transactions.groupId),
				eq(groupUsers.userId, input.userId),
			),
		)
		.leftJoin(
			groupCategories,
			and(
				eq(groupCategories.id, transactions.categoryId),
				eq(groupCategories.groupId, transactions.groupId),
			),
		)
		.where(
			and(
				isNull(transactions.deletedAt),
				isNotNull(groupUsers.memberId),
				input.groupId === undefined
					? undefined
					: eq(transactions.groupId, input.groupId),
				input.type === undefined
					? undefined
					: eq(transactions.type, input.type),
				input.searchPattern === undefined
					? undefined
					: sql`${transactions.descriptionSearch} like ${input.searchPattern} escape '\\'`,
				or(
					exists(
						executor
							.select({ id: transactionPayers.transactionId })
							.from(transactionPayers)
							.where(
								and(
									eq(transactionPayers.transactionId, transactions.id),
									eq(transactionPayers.memberId, groupUsers.memberId),
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
									eq(transactionShares.memberId, groupUsers.memberId),
								),
							),
					),
				),
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

export function listPersonalTransactionPayers(
	executor: DbExecutor,
	transactionIds: string[],
) {
	if (transactionIds.length === 0) return Promise.resolve([]);
	return executor
		.select({
			transactionId: transactionPayers.transactionId,
			memberId: transactionPayers.memberId,
			memberName: members.name,
			amount: transactionPayers.amount,
		})
		.from(transactionPayers)
		.innerJoin(members, eq(members.id, transactionPayers.memberId))
		.where(inArray(transactionPayers.transactionId, transactionIds))
		.orderBy(asc(members.position));
}

export function listPersonalTransactionShares(
	executor: DbExecutor,
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
		.innerJoin(members, eq(members.id, transactionShares.memberId))
		.where(inArray(transactionShares.transactionId, transactionIds))
		.orderBy(asc(members.position));
}

export async function listOpenDisputeTransactionIds(
	executor: DbExecutor,
	transactionIds: string[],
): Promise<Set<string>> {
	if (transactionIds.length === 0) return new Set();
	const rows = await executor
		.select({ transactionId: transactionDisputes.transactionId })
		.from(transactionDisputes)
		.where(
			and(
				inArray(transactionDisputes.transactionId, transactionIds),
				isNull(transactionDisputes.resolvedAt),
			),
		);
	return new Set(rows.map((row) => row.transactionId));
}
