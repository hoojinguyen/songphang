import { and, asc, eq, isNull, ne, sql } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { groupCategories } from "./schema-categories.js";

export const CATEGORY_COLUMNS = {
	id: groupCategories.id,
	groupId: groupCategories.groupId,
	name: groupCategories.name,
	nameKey: groupCategories.nameKey,
	color: groupCategories.color,
	archivedAt: groupCategories.archivedAt,
};

export function listGroupCategories(executor: DbExecutor, groupId: string) {
	return executor
		.select(CATEGORY_COLUMNS)
		.from(groupCategories)
		.where(eq(groupCategories.groupId, groupId))
		.orderBy(
			sql`${groupCategories.archivedAt} is not null`,
			asc(groupCategories.createdAt),
			asc(groupCategories.id),
		);
}

export async function countLiveCategories(
	executor: DbExecutor,
	groupId: string,
) {
	const [row] = await executor
		.select({ count: sql<number>`count(*)::int` })
		.from(groupCategories)
		.where(
			and(
				eq(groupCategories.groupId, groupId),
				isNull(groupCategories.archivedAt),
			),
		);
	return row?.count ?? 0;
}

export async function findCategoryById(
	executor: DbExecutor,
	groupId: string,
	id: string,
) {
	const [row] = await executor
		.select(CATEGORY_COLUMNS)
		.from(groupCategories)
		.where(
			and(eq(groupCategories.groupId, groupId), eq(groupCategories.id, id)),
		)
		.limit(1);
	return row ?? null;
}

export async function findLiveCategoryByNameKey(
	executor: DbExecutor,
	input: { groupId: string; nameKey: string; excludeId?: string },
) {
	const [row] = await executor
		.select(CATEGORY_COLUMNS)
		.from(groupCategories)
		.where(
			and(
				eq(groupCategories.groupId, input.groupId),
				eq(groupCategories.nameKey, input.nameKey),
				isNull(groupCategories.archivedAt),
				input.excludeId === undefined
					? undefined
					: ne(groupCategories.id, input.excludeId),
			),
		)
		.limit(1);
	return row ?? null;
}

export async function insertCategory(
	executor: DbExecutor,
	input: typeof groupCategories.$inferInsert,
) {
	const [row] = await executor
		.insert(groupCategories)
		.values(input)
		.returning(CATEGORY_COLUMNS);
	if (row === undefined) throw new Error("Category insert failed");
	return row;
}

export async function insertCategories(
	executor: DbExecutor,
	rows: (typeof groupCategories.$inferInsert)[],
) {
	if (rows.length > 0) {
		await executor.insert(groupCategories).values(rows);
	}
}

export async function updateCategoryRow(
	executor: DbExecutor,
	input: {
		groupId: string;
		id: string;
		changes: {
			name?: string;
			nameKey?: string;
			color?: string;
			archivedAt?: Date | null;
			updatedAt: Date;
		};
	},
) {
	const [row] = await executor
		.update(groupCategories)
		.set(input.changes)
		.where(
			and(
				eq(groupCategories.groupId, input.groupId),
				eq(groupCategories.id, input.id),
			),
		)
		.returning(CATEGORY_COLUMNS);
	return row ?? null;
}
