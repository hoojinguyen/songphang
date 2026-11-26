import {
	and,
	asc,
	desc,
	eq,
	inArray,
	isNotNull,
	isNull,
	lte,
	sql,
} from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { groups, groupUsers } from "./schema-groups.js";
import { recurringExpenses } from "./schema-recurring.js";

export const RECURRING_EXPENSE_COLUMNS = {
	id: recurringExpenses.id,
	groupId: recurringExpenses.groupId,
	mode: recurringExpenses.mode,
	active: recurringExpenses.active,
	description: recurringExpenses.description,
	amount: recurringExpenses.amount,
	category: recurringExpenses.category,
	categoryId: recurringExpenses.categoryId,
	payersTemplate: recurringExpenses.payersTemplate,
	splitTemplate: recurringExpenses.splitTemplate,
	frequency: recurringExpenses.frequency,
	dayOfWeek: recurringExpenses.dayOfWeek,
	dayOfMonth: recurringExpenses.dayOfMonth,
	monthOfYear: recurringExpenses.monthOfYear,
	nextDueDate: recurringExpenses.nextDueDate,
	pendingDueDate: recurringExpenses.pendingDueDate,
	lastProcessedDueDate: recurringExpenses.lastProcessedDueDate,
	lastPostedAt: recurringExpenses.lastPostedAt,
	lastTransactionId: recurringExpenses.lastTransactionId,
	pauseReason: recurringExpenses.pauseReason,
	createdBy: recurringExpenses.createdBy,
	updatedBy: recurringExpenses.updatedBy,
	createdAt: recurringExpenses.createdAt,
	updatedAt: recurringExpenses.updatedAt,
};

export type RecurringExpenseRow = typeof recurringExpenses.$inferSelect;

export function listGroupRecurringExpenses(
	executor: DbExecutor,
	groupId: string,
): Promise<RecurringExpenseRow[]> {
	return executor
		.select(RECURRING_EXPENSE_COLUMNS)
		.from(recurringExpenses)
		.where(eq(recurringExpenses.groupId, groupId))
		.orderBy(
			sql`(${recurringExpenses.pendingDueDate} is not null) desc`,
			desc(recurringExpenses.active),
			asc(recurringExpenses.nextDueDate),
			desc(recurringExpenses.createdAt),
		);
}

export async function findRecurringExpense(
	executor: DbExecutor,
	groupId: string,
	recurringId: string,
): Promise<RecurringExpenseRow | null> {
	const [row] = await executor
		.select(RECURRING_EXPENSE_COLUMNS)
		.from(recurringExpenses)
		.where(
			and(
				eq(recurringExpenses.groupId, groupId),
				eq(recurringExpenses.id, recurringId),
			),
		)
		.limit(1);
	return row ?? null;
}

export async function countGroupRecurringExpenses(
	executor: DbExecutor,
	groupId: string,
): Promise<number> {
	const [row] = await executor
		.select({ count: sql<number>`count(*)::int` })
		.from(recurringExpenses)
		.where(eq(recurringExpenses.groupId, groupId));
	return row?.count ?? 0;
}

export async function insertRecurringExpense(
	executor: DbExecutor,
	input: typeof recurringExpenses.$inferInsert,
): Promise<RecurringExpenseRow> {
	const [row] = await executor
		.insert(recurringExpenses)
		.values(input)
		.returning(RECURRING_EXPENSE_COLUMNS);
	if (!row) throw new Error("Recurring expense insert failed");
	return row;
}

export async function updateRecurringExpense(
	executor: DbExecutor,
	groupId: string,
	recurringId: string,
	changes: Partial<typeof recurringExpenses.$inferInsert>,
): Promise<RecurringExpenseRow | null> {
	const [row] = await executor
		.update(recurringExpenses)
		.set(changes)
		.where(
			and(
				eq(recurringExpenses.groupId, groupId),
				eq(recurringExpenses.id, recurringId),
			),
		)
		.returning(RECURRING_EXPENSE_COLUMNS);
	return row ?? null;
}

export function deleteRecurringExpense(
	executor: DbExecutor,
	groupId: string,
	recurringId: string,
) {
	return executor
		.delete(recurringExpenses)
		.where(
			and(
				eq(recurringExpenses.groupId, groupId),
				eq(recurringExpenses.id, recurringId),
			),
		);
}

export function listActiveRecurringExpensesInGroup(
	executor: DbExecutor,
	groupId: string,
): Promise<RecurringExpenseRow[]> {
	return executor
		.select(RECURRING_EXPENSE_COLUMNS)
		.from(recurringExpenses)
		.where(
			and(
				eq(recurringExpenses.groupId, groupId),
				eq(recurringExpenses.active, true),
			),
		);
}

export function listDueRecurringExpenses(
	executor: DbExecutor,
	todayVN: string,
): Promise<Array<{ id: string; groupId: string }>> {
	return executor
		.select({
			id: recurringExpenses.id,
			groupId: recurringExpenses.groupId,
		})
		.from(recurringExpenses)
		.innerJoin(groups, eq(groups.id, recurringExpenses.groupId))
		.where(
			and(
				eq(recurringExpenses.active, true),
				isNull(groups.archivedAt),
				lte(recurringExpenses.nextDueDate, todayVN),
			),
		)
		.orderBy(asc(recurringExpenses.nextDueDate), asc(recurringExpenses.id));
}

export function listDueVariableRecurringForUser(
	executor: DbExecutor,
	userId: string,
) {
	return executor
		.select({
			id: recurringExpenses.id,
			groupId: recurringExpenses.groupId,
			groupName: groups.name,
			description: recurringExpenses.description,
			dueDate: recurringExpenses.pendingDueDate,
			suggestedAmount: recurringExpenses.amount,
			payersTemplate: recurringExpenses.payersTemplate,
			createdBy: recurringExpenses.createdBy,
			updatedBy: recurringExpenses.updatedBy,
			callerRole: groupUsers.role,
			callerMemberId: groupUsers.memberId,
		})
		.from(recurringExpenses)
		.innerJoin(groups, eq(groups.id, recurringExpenses.groupId))
		.innerJoin(groupUsers, eq(groupUsers.groupId, groups.id))
		.where(
			and(
				eq(groupUsers.userId, userId),
				inArray(groupUsers.role, ["owner", "editor"]),
				isNull(groups.archivedAt),
				eq(recurringExpenses.active, true),
				eq(recurringExpenses.mode, "variable"),
				isNotNull(recurringExpenses.pendingDueDate),
			),
		)
		.orderBy(
			asc(recurringExpenses.pendingDueDate),
			asc(recurringExpenses.createdAt),
		);
}

export async function listGroupRecurringRowsForMemberCheck(
	executor: DbExecutor,
	groupId: string,
) {
	return executor
		.select({
			id: recurringExpenses.id,
			payersTemplate: recurringExpenses.payersTemplate,
			splitTemplate: recurringExpenses.splitTemplate,
		})
		.from(recurringExpenses)
		.where(eq(recurringExpenses.groupId, groupId));
}
