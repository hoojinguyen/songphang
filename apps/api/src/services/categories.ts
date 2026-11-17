import { z } from "@hono/zod-openapi";
import {
	CategoriesResponse,
	CategoryDto,
	CategoryResponse,
	type CreateCategoryRequest,
	type UpdateCategoryRequest,
} from "@songphang/contract";
import { foldVietnamese } from "@songphang/core";
import {
	countLiveCategories,
	type DbExecutor,
	findCategoryById,
	findLiveCategoryByNameKey,
	insertCategory,
	listGroupCategories,
	lockGroup,
	updateCategoryRow,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { getGroupAccess } from "../auth/group-access.js";
import { AppError } from "../errors.js";

const MAX_LIVE_CATEGORIES = 30;

export function normalizeCategoryKey(name: string): string {
	return foldVietnamese(name.trim()).replace(/\s+/g, " ");
}

function toDto(row: Awaited<ReturnType<typeof listGroupCategories>>[number]) {
	return CategoryDto.parse({
		id: row.id,
		name: row.name,
		color: row.color,
		archived: row.archivedAt !== null,
	});
}

export async function assertLiveCategory(
	executor: DbExecutor,
	groupId: string,
	categoryId: string | null,
): Promise<void> {
	if (categoryId === null) return;
	const row = await findCategoryById(executor, groupId, categoryId);
	if (row === null || row.archivedAt !== null) {
		throw new AppError(
			400,
			"VALIDATION_FAILED",
			"Category is missing or archived",
			{ categoryId: ["Invalid or archived category"] },
		);
	}
}

export async function listCategories(deps: AppDeps, groupId: string) {
	const rows = await listGroupCategories(deps.db, groupId);
	return CategoriesResponse.parse({ categories: rows.map(toDto) });
}

export async function createCategory(
	executor: DbExecutor,
	input: {
		groupId: string;
		userId: string;
		request: CreateCategoryRequest;
		now: Date;
	},
) {
	await lockGroup(executor, input.groupId);
	await getGroupAccess(executor, { ...input, minimumRole: "editor" });
	const liveCount = await countLiveCategories(executor, input.groupId);
	if (liveCount >= MAX_LIVE_CATEGORIES)
		throw new AppError(422, "LIMIT_REACHED", "Category limit reached");
	const nameKey = normalizeCategoryKey(input.request.name);
	const existing = await findLiveCategoryByNameKey(executor, {
		groupId: input.groupId,
		nameKey,
	});
	if (existing !== null)
		throw new AppError(409, "CATEGORY_EXISTS", "Category already exists");
	const row = await insertCategory(executor, {
		groupId: input.groupId,
		name: input.request.name,
		nameKey,
		color: input.request.color,
		createdAt: input.now,
		updatedAt: input.now,
	});
	return CategoryResponse.parse({ category: toDto(row) });
}

export async function updateCategory(
	deps: AppDeps,
	input: {
		groupId: string;
		userId: string;
		id: string;
		request: UpdateCategoryRequest;
	},
) {
	const result = await deps.db.transaction(async (executor) => {
		await lockGroup(executor, input.groupId);
		await getGroupAccess(executor, { ...input, minimumRole: "editor" });
		if (!z.uuid().safeParse(input.id).success)
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		const current = await findCategoryById(executor, input.groupId, input.id);
		if (current === null)
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		const nameKey =
			input.request.name === undefined
				? undefined
				: normalizeCategoryKey(input.request.name);
		if (nameKey !== undefined && current.archivedAt === null) {
			const conflict = await findLiveCategoryByNameKey(executor, {
				groupId: input.groupId,
				nameKey,
				excludeId: current.id,
			});
			if (conflict !== null)
				throw new AppError(409, "CATEGORY_EXISTS", "Category already exists");
		}
		const updated = await updateCategoryRow(executor, {
			groupId: input.groupId,
			id: input.id,
			changes: {
				...(input.request.name === undefined
					? {}
					: {
							name: input.request.name,
							nameKey: normalizeCategoryKey(input.request.name),
						}),
				...(input.request.color === undefined
					? {}
					: { color: input.request.color }),
				updatedAt: deps.now(),
			},
		});
		if (updated === null)
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		return CategoryResponse.parse({ category: toDto(updated) });
	});
	deps.events.publishChanged(input.groupId, ["categories"]);
	return result;
}

export async function archiveCategory(
	deps: AppDeps,
	input: { groupId: string; userId: string; id: string },
) {
	await deps.db.transaction(async (executor) => {
		await lockGroup(executor, input.groupId);
		await getGroupAccess(executor, { ...input, minimumRole: "editor" });
		if (!z.uuid().safeParse(input.id).success)
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		const current = await findCategoryById(executor, input.groupId, input.id);
		if (current === null)
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		if (current.archivedAt === null) {
			await updateCategoryRow(executor, {
				groupId: input.groupId,
				id: input.id,
				changes: { archivedAt: deps.now(), updatedAt: deps.now() },
			});
		}
	});
	deps.events.publishChanged(input.groupId, ["categories"]);
}
