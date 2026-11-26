import { and, desc, eq, inArray, isNotNull, isNull, lt, or } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { attachments } from "./schema-attachments.js";
import { groupCategories } from "./schema-categories.js";
import { groups } from "./schema-groups.js";
import { transactions } from "./schema-transactions.js";
import { countedTransaction, type TransactionCursor } from "./transactions.js";

export async function readGroupGuestLink(
	executor: DbExecutor,
	groupId: string,
) {
	const [row] = await executor
		.select({
			active: groups.guestLinkActive,
			token: groups.guestToken,
			createdAt: groups.guestLinkCreatedAt,
		})
		.from(groups)
		.where(eq(groups.id, groupId))
		.limit(1);
	return row ?? null;
}

export function updateGroupGuestLink(
	executor: DbExecutor,
	input: {
		groupId: string;
		active: boolean;
		token: string | null;
		createdAt: Date | null;
		now: Date;
	},
) {
	return executor
		.update(groups)
		.set({
			guestLinkActive: input.active,
			guestToken: input.token,
			guestLinkCreatedAt: input.createdAt,
			updatedAt: input.now,
		})
		.where(eq(groups.id, input.groupId));
}

export async function findGroupByGuestToken(
	executor: DbExecutor,
	token: string,
) {
	const [row] = await executor
		.select({
			id: groups.id,
			name: groups.name,
			currency: groups.currency,
			minimizeDebts: groups.minimizeDebts,
			archivedAt: groups.archivedAt,
			createdAt: groups.createdAt,
		})
		.from(groups)
		.where(and(eq(groups.guestToken, token), eq(groups.guestLinkActive, true)))
		.limit(1);
	return row ?? null;
}

export function listGuestTransactionRows(
	executor: DbExecutor,
	input: {
		groupId: string;
		cycleFilter: "current" | string;
		cursor: TransactionCursor | null;
		limit: number;
	},
) {
	const cursor = input.cursor;
	return executor
		.select({
			id: transactions.id,
			type: transactions.type,
			description: transactions.description,
			amount: transactions.amount,
			currency: transactions.currency,
			occurredAt: transactions.occurredAt,
			category: transactions.category,
			categoryId: transactions.categoryId,
			categoryName: groupCategories.name,
			categoryColor: groupCategories.color,
			split: transactions.splitInput,
			paymentChannel: transactions.paymentChannel,
			paymentNote: transactions.paymentNote,
			cycleId: transactions.cycleId,
		})
		.from(transactions)
		.leftJoin(groupCategories, eq(groupCategories.id, transactions.categoryId))
		.where(
			and(
				eq(transactions.groupId, input.groupId),
				countedTransaction("transactions"),
				input.cycleFilter === "current"
					? isNull(transactions.cycleId)
					: eq(transactions.cycleId, input.cycleFilter),
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

export async function findGuestAttachment(
	executor: DbExecutor,
	groupId: string,
	attachmentId: string,
) {
	const [row] = await executor
		.select({
			id: attachments.id,
			storageKey: attachments.storageKey,
			contentType: attachments.contentType,
		})
		.from(attachments)
		.innerJoin(transactions, eq(transactions.id, attachments.transactionId))
		.where(
			and(
				eq(attachments.groupId, groupId),
				eq(attachments.id, attachmentId),
				eq(attachments.purpose, "expense"),
				isNotNull(attachments.transactionId),
				countedTransaction("transactions"),
				inArray(transactions.type, ["expense", "income"]),
			),
		)
		.limit(1);
	return row ?? null;
}
