import { z } from "@hono/zod-openapi";
import {
	type CreateRecurringExpenseRequest,
	RecurringExpenseDto,
	RecurringExpenseResponse,
	RecurringExpensesResponse,
	RecurringFrequency,
	RecurringPayerTemplateEntry,
	SplitInput,
	TransactionCategory,
	type UpdateRecurringExpenseRequest,
} from "@songphang/contract";
import {
	computeNextDueDate,
	computeShares,
	type RecurringSchedule,
	todayInVietnam,
} from "@songphang/core";
import {
	countGroupRecurringExpenses,
	type DbExecutor,
	deleteRecurringExpense,
	findRecurringExpense,
	insertActivity,
	insertRecurringExpense,
	listActiveRecurringExpensesInGroup,
	listGroupMembers,
	listGroupRecurringExpenses,
	listGroupRecurringRowsForMemberCheck,
	lockGroup,
	type RecurringExpenseRow,
	updateRecurringExpense,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { getGroupAccess } from "../auth/group-access.js";
import { AppError } from "../errors.js";
import { assertLiveCategory } from "./categories.js";
import { assertGroupRowNotArchived } from "./group-guards.js";

const MAX_RECURRING_PER_GROUP = 50;

export function toRecurringSchedule(input: {
	frequency: string;
	dayOfWeek: number | null;
	dayOfMonth: number | null;
	monthOfYear: number | null;
}): RecurringSchedule {
	if (input.frequency === "weekly") {
		if (input.dayOfWeek === null) {
			throw new AppError(400, "VALIDATION_FAILED", "dayOfWeek is required");
		}
		return { frequency: "weekly", dayOfWeek: input.dayOfWeek };
	}
	if (input.frequency === "monthly" || input.frequency === "quarterly") {
		if (input.dayOfMonth === null) {
			throw new AppError(400, "VALIDATION_FAILED", "dayOfMonth is required");
		}
		return { frequency: input.frequency, dayOfMonth: input.dayOfMonth };
	}
	if (input.frequency === "yearly") {
		if (input.monthOfYear === null || input.dayOfMonth === null) {
			throw new AppError(
				400,
				"VALIDATION_FAILED",
				"monthOfYear and dayOfMonth are required",
			);
		}
		return {
			frequency: "yearly",
			monthOfYear: input.monthOfYear,
			dayOfMonth: input.dayOfMonth,
		};
	}
	throw new AppError(400, "VALIDATION_FAILED", "Invalid frequency");
}

export function splitTemplateMemberIds(split: SplitInput): string[] {
	if (split.method === "equal" || split.method === "exact") {
		return [...split.members];
	}
	if (split.method === "items") {
		return [...new Set(split.items.flatMap((item) => item.memberIds))];
	}
	return split.entries.map((entry) => entry.memberId);
}

export function toRecurringExpenseDto(
	row: RecurringExpenseRow,
): RecurringExpenseDto {
	return RecurringExpenseDto.parse({
		id: row.id,
		groupId: row.groupId,
		mode: row.mode,
		active: row.active,
		description: row.description,
		amount: row.amount,
		category: TransactionCategory.nullable().parse(row.category),
		categoryId: row.categoryId,
		payersTemplate: z
			.array(RecurringPayerTemplateEntry)
			.parse(row.payersTemplate),
		splitTemplate: SplitInput.parse(row.splitTemplate),
		frequency: RecurringFrequency.parse(row.frequency),
		dayOfWeek: row.dayOfWeek,
		dayOfMonth: row.dayOfMonth,
		monthOfYear: row.monthOfYear,
		nextDueDate: row.nextDueDate,
		pendingDueDate: row.pendingDueDate,
		lastProcessedDueDate: row.lastProcessedDueDate,
		lastPostedAt: row.lastPostedAt?.toISOString() ?? null,
		lastTransactionId: row.lastTransactionId,
		pauseReason: row.pauseReason,
		createdAt: row.createdAt.toISOString(),
		updatedAt: row.updatedAt.toISOString(),
	});
}

async function validateRecurringTemplate(
	executor: DbExecutor,
	input: {
		groupId: string;
		mode: "fixed" | "variable";
		amount: number | null;
		payersTemplate: Array<z.infer<typeof RecurringPayerTemplateEntry>>;
		splitTemplate: SplitInput;
	},
) {
	if (input.mode === "fixed") {
		if (
			input.amount === null ||
			!input.payersTemplate.every((payer) => payer.amount !== undefined)
		) {
			throw new AppError(
				400,
				"VALIDATION_FAILED",
				"Fixed recurring expense requires amount and payer amounts",
			);
		}
	} else if (
		input.payersTemplate.length !== 1 ||
		(input.splitTemplate.method !== "equal" &&
			input.splitTemplate.method !== "shares" &&
			input.splitTemplate.method !== "percent")
	) {
		throw new AppError(
			400,
			"VALIDATION_FAILED",
			"Variable recurring expense requires 1 payer and equal/shares/percent split",
		);
	}

	const members = await listGroupMembers(executor, input.groupId);
	const memberById = new Map(members.map((m) => [m.id, m]));
	const payerIds = input.payersTemplate.map((p) => p.memberId);
	const splitIds = splitTemplateMemberIds(input.splitTemplate);

	for (const id of [...payerIds, ...splitIds]) {
		const member = memberById.get(id);
		if (!member) {
			throw new AppError(
				400,
				"MEMBER_NOT_IN_GROUP",
				"Member does not belong to group",
			);
		}
		if (!member.active) {
			throw new AppError(
				422,
				"RECURRING_MEMBER_INACTIVE",
				"Referenced member or fund is inactive",
			);
		}
	}
	if (splitIds.some((id) => memberById.get(id)?.kind === "fund")) {
		throw new AppError(
			422,
			"FUND_CANNOT_SHARE",
			"Fund member cannot bear a share",
		);
	}

	if (input.mode === "fixed" && input.amount !== null) {
		const paid = input.payersTemplate.reduce(
			(sum, payer) => sum + (payer.amount ?? 0),
			0,
		);
		if (paid !== input.amount) {
			throw new AppError(
				400,
				"PAYER_TOTAL_MISMATCH",
				"Payer total differs from amount",
				{ expected: input.amount, actual: paid },
			);
		}
		const splitResult = computeShares(
			input.amount,
			input.splitTemplate,
			members.map((m) => m.id),
		);
		if (!splitResult.ok) {
			if (splitResult.code === "ITEM_UNASSIGNED") {
				throw new AppError(
					400,
					"ITEM_UNASSIGNED",
					"Item has no assigned members",
					{ itemIndex: splitResult.itemIndex },
				);
			}
			throw new AppError(
				400,
				splitResult.code,
				"Split total differs from amount",
				{
					expected: splitResult.expected,
					actual: splitResult.actual,
				},
			);
		}
	}
}

export async function listRecurringExpenses(deps: AppDeps, groupId: string) {
	return deps.db.transaction(
		async (executor) => {
			const rows = await listGroupRecurringExpenses(executor, groupId);
			return RecurringExpensesResponse.parse({
				recurringExpenses: rows.map(toRecurringExpenseDto),
			});
		},
		{ isolationLevel: "repeatable read", accessMode: "read only" },
	);
}

export async function createRecurringExpenseIn(
	executor: DbExecutor,
	input: {
		groupId: string;
		userId: string;
		request: CreateRecurringExpenseRequest;
		now: Date;
		strictlyAfterToday?: boolean;
		lastTransactionId?: string | null;
	},
) {
	const count = await countGroupRecurringExpenses(executor, input.groupId);
	if (count >= MAX_RECURRING_PER_GROUP) {
		throw new AppError(
			422,
			"LIMIT_REACHED",
			"Group has reached the recurring expense limit",
		);
	}
	await assertLiveCategory(executor, input.groupId, input.request.categoryId);

	const amount =
		input.request.mode === "fixed" ? (input.request.amount ?? null) : null;
	await validateRecurringTemplate(executor, {
		groupId: input.groupId,
		mode: input.request.mode,
		amount,
		payersTemplate: input.request.payersTemplate,
		splitTemplate: input.request.splitTemplate,
	});

	const schedule = toRecurringSchedule({
		frequency: input.request.frequency,
		dayOfWeek: input.request.dayOfWeek ?? null,
		dayOfMonth: input.request.dayOfMonth ?? null,
		monthOfYear: input.request.monthOfYear ?? null,
	});
	const todayVN = todayInVietnam(input.now);
	const nextDueDate = computeNextDueDate(
		schedule,
		todayVN,
		!input.strictlyAfterToday,
	);

	const row = await insertRecurringExpense(executor, {
		groupId: input.groupId,
		mode: input.request.mode,
		active: true,
		description: input.request.description,
		amount: input.request.amount ?? null,
		category: input.request.category ?? null,
		categoryId: input.request.categoryId ?? null,
		payersTemplate: input.request.payersTemplate,
		splitTemplate: input.request.splitTemplate,
		frequency: input.request.frequency,
		dayOfWeek: schedule.frequency === "weekly" ? schedule.dayOfWeek : null,
		dayOfMonth: schedule.frequency === "weekly" ? null : schedule.dayOfMonth,
		monthOfYear: schedule.frequency === "yearly" ? schedule.monthOfYear : null,
		nextDueDate,
		pendingDueDate: null,
		lastProcessedDueDate: null,
		lastPostedAt: input.lastTransactionId ? input.now : null,
		lastTransactionId: input.lastTransactionId ?? null,
		pauseReason: null,
		createdBy: input.userId,
		updatedBy: input.userId,
		createdAt: input.now,
		updatedAt: input.now,
	});
	await insertActivity(executor, {
		groupId: input.groupId,
		actorUserId: input.userId,
		action: "recurring.created",
		entityType: "recurring_expense",
		entityId: row.id,
		summary: row.description,
		after: {
			mode: row.mode,
			frequency: row.frequency,
			nextDueDate: row.nextDueDate,
		},
		createdAt: input.now,
	});
	return RecurringExpenseResponse.parse({
		recurringExpense: toRecurringExpenseDto(row),
	});
}

export async function createRecurringExpense(
	executor: DbExecutor,
	input: {
		groupId: string;
		userId: string;
		request: CreateRecurringExpenseRequest;
		now: Date;
	},
) {
	const group = await lockGroup(executor, input.groupId);
	await getGroupAccess(executor, {
		groupId: input.groupId,
		userId: input.userId,
		minimumRole: "editor",
	});
	assertGroupRowNotArchived(group);
	return createRecurringExpenseIn(executor, input);
}

function resolveCategoryPatch(
	request: UpdateRecurringExpenseRequest,
	before: RecurringExpenseRow,
): { category: string | null; categoryId: string | null } {
	if (request.category === undefined && request.categoryId === undefined) {
		return { category: before.category, categoryId: before.categoryId };
	}
	if (request.category !== undefined && request.category !== null) {
		return { category: request.category, categoryId: null };
	}
	if (request.categoryId !== undefined && request.categoryId !== null) {
		return { category: null, categoryId: request.categoryId };
	}
	return { category: null, categoryId: null };
}

export async function editRecurringExpense(
	deps: AppDeps,
	input: {
		groupId: string;
		userId: string;
		recurringId: string;
		request: UpdateRecurringExpenseRequest;
	},
) {
	if (!z.uuid().safeParse(input.recurringId).success) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	const result = await deps.db.transaction(async (executor) => {
		const group = await lockGroup(executor, input.groupId);
		await getGroupAccess(executor, {
			groupId: input.groupId,
			userId: input.userId,
			minimumRole: "editor",
		});
		assertGroupRowNotArchived(group);
		const before = await findRecurringExpense(
			executor,
			input.groupId,
			input.recurringId,
		);
		if (before === null) {
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		}
		const nextMode =
			input.request.mode ?? (before.mode === "fixed" ? "fixed" : "variable");
		const nextActive = input.request.active ?? before.active;
		const nextDescription = input.request.description ?? before.description;
		const nextAmount =
			input.request.amount === undefined ? before.amount : input.request.amount;
		const { category: nextCategory, categoryId: nextCategoryId } =
			resolveCategoryPatch(input.request, before);
		if (nextCategoryId !== null && nextCategoryId !== before.categoryId) {
			await assertLiveCategory(executor, input.groupId, nextCategoryId);
		}
		const nextPayersTemplate =
			input.request.payersTemplate ??
			z.array(RecurringPayerTemplateEntry).parse(before.payersTemplate);
		const nextSplitTemplate =
			input.request.splitTemplate ?? SplitInput.parse(before.splitTemplate);
		const nextFrequency =
			input.request.frequency ?? RecurringFrequency.parse(before.frequency);
		const nextDayOfWeek =
			input.request.dayOfWeek !== undefined
				? input.request.dayOfWeek
				: input.request.frequency !== undefined &&
						input.request.frequency !== "weekly"
					? null
					: before.dayOfWeek;
		const nextDayOfMonth =
			input.request.dayOfMonth !== undefined
				? input.request.dayOfMonth
				: input.request.frequency === "weekly"
					? null
					: before.dayOfMonth;
		const nextMonthOfYear =
			input.request.monthOfYear !== undefined
				? input.request.monthOfYear
				: input.request.frequency !== undefined &&
						input.request.frequency !== "yearly"
					? null
					: before.monthOfYear;

		const schedule = toRecurringSchedule({
			frequency: nextFrequency,
			dayOfWeek: nextDayOfWeek,
			dayOfMonth: nextDayOfMonth,
			monthOfYear: nextMonthOfYear,
		});
		await validateRecurringTemplate(executor, {
			groupId: input.groupId,
			mode: nextMode,
			amount: nextAmount,
			payersTemplate: nextPayersTemplate,
			splitTemplate: nextSplitTemplate,
		});

		const now = deps.now();
		const todayVN = todayInVietnam(now);
		const scheduleChanged =
			input.request.frequency !== undefined ||
			input.request.dayOfWeek !== undefined ||
			input.request.dayOfMonth !== undefined ||
			input.request.monthOfYear !== undefined;
		const resumingStale =
			!before.active && nextActive && before.nextDueDate < todayVN;
		const nextDueDate =
			scheduleChanged || resumingStale
				? computeNextDueDate(schedule, todayVN, true)
				: before.nextDueDate;

		const nextPendingDueDate =
			!nextActive || nextMode === "fixed" ? null : before.pendingDueDate;
		const nextPauseReason = nextActive ? null : before.pauseReason;

		const updated = await updateRecurringExpense(
			executor,
			input.groupId,
			before.id,
			{
				mode: nextMode,
				active: nextActive,
				description: nextDescription,
				amount: nextAmount,
				category: nextCategory,
				categoryId: nextCategoryId,
				payersTemplate: nextPayersTemplate,
				splitTemplate: nextSplitTemplate,
				frequency: nextFrequency,
				dayOfWeek: schedule.frequency === "weekly" ? schedule.dayOfWeek : null,
				dayOfMonth:
					schedule.frequency === "weekly" ? null : schedule.dayOfMonth,
				monthOfYear:
					schedule.frequency === "yearly" ? schedule.monthOfYear : null,
				nextDueDate,
				pendingDueDate: nextPendingDueDate,
				pauseReason: nextPauseReason,
				updatedBy: input.userId,
				updatedAt: now,
			},
		);
		if (updated === null) throw new Error("Updated recurring expense missing");
		await insertActivity(executor, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: "recurring.updated",
			entityType: "recurring_expense",
			entityId: updated.id,
			summary: updated.description,
			before: {
				active: before.active,
				nextDueDate: before.nextDueDate,
				amount: before.amount,
			},
			after: {
				active: updated.active,
				nextDueDate: updated.nextDueDate,
				amount: updated.amount,
			},
			createdAt: now,
		});
		return RecurringExpenseResponse.parse({
			recurringExpense: toRecurringExpenseDto(updated),
		});
	});
	deps.events.publishChanged(input.groupId, ["activity", "recurringExpenses"]);
	return result;
}

export async function removeRecurringExpense(
	deps: AppDeps,
	input: { groupId: string; userId: string; recurringId: string },
) {
	if (!z.uuid().safeParse(input.recurringId).success) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	await deps.db.transaction(async (executor) => {
		const group = await lockGroup(executor, input.groupId);
		if (group === null) {
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		}
		await getGroupAccess(executor, {
			groupId: input.groupId,
			userId: input.userId,
			minimumRole: "editor",
		});
		const before = await findRecurringExpense(
			executor,
			input.groupId,
			input.recurringId,
		);
		if (before === null) {
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		}
		const now = deps.now();
		await deleteRecurringExpense(executor, input.groupId, before.id);
		await insertActivity(executor, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: "recurring.deleted",
			entityType: "recurring_expense",
			entityId: before.id,
			summary: before.description,
			before: { description: before.description, mode: before.mode },
			createdAt: now,
		});
	});
	deps.events.publishChanged(input.groupId, ["activity", "recurringExpenses"]);
}

export async function skipRecurringExpense(
	deps: AppDeps,
	input: { groupId: string; userId: string; recurringId: string },
) {
	if (!z.uuid().safeParse(input.recurringId).success) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	const result = await deps.db.transaction(async (executor) => {
		const group = await lockGroup(executor, input.groupId);
		await getGroupAccess(executor, {
			groupId: input.groupId,
			userId: input.userId,
			minimumRole: "editor",
		});
		assertGroupRowNotArchived(group);
		const before = await findRecurringExpense(
			executor,
			input.groupId,
			input.recurringId,
		);
		if (before === null) {
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		}
		const now = deps.now();
		const nextDueDate =
			before.pendingDueDate !== null
				? before.nextDueDate
				: computeNextDueDate(
						toRecurringSchedule({
							frequency: before.frequency,
							dayOfWeek: before.dayOfWeek,
							dayOfMonth: before.dayOfMonth,
							monthOfYear: before.monthOfYear,
						}),
						before.nextDueDate,
						false,
					);
		const updated = await updateRecurringExpense(
			executor,
			input.groupId,
			before.id,
			{
				pendingDueDate: null,
				nextDueDate,
				updatedBy: input.userId,
				updatedAt: now,
			},
		);
		if (updated === null) throw new Error("Skipped recurring expense missing");
		await insertActivity(executor, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: "recurring.skipped",
			entityType: "recurring_expense",
			entityId: updated.id,
			summary: updated.description,
			before: {
				pendingDueDate: before.pendingDueDate,
				nextDueDate: before.nextDueDate,
			},
			after: {
				pendingDueDate: updated.pendingDueDate,
				nextDueDate: updated.nextDueDate,
			},
			createdAt: now,
		});
		return RecurringExpenseResponse.parse({
			recurringExpense: toRecurringExpenseDto(updated),
		});
	});
	deps.events.publishChanged(input.groupId, ["activity", "recurringExpenses"]);
	return result;
}

export async function pauseRecurringTemplatesForMember(
	executor: DbExecutor,
	input: {
		groupId: string;
		memberId: string;
		actorUserId: string;
		now: Date;
	},
): Promise<number> {
	const activeRows = await listActiveRecurringExpensesInGroup(
		executor,
		input.groupId,
	);
	let pausedCount = 0;
	for (const row of activeRows) {
		const payers = z
			.array(RecurringPayerTemplateEntry)
			.parse(row.payersTemplate);
		const split = SplitInput.parse(row.splitTemplate);
		const referencedIds = [
			...payers.map((p) => p.memberId),
			...splitTemplateMemberIds(split),
		];
		if (!referencedIds.includes(input.memberId)) continue;
		await updateRecurringExpense(executor, input.groupId, row.id, {
			active: false,
			pauseReason: "member_invalid",
			pendingDueDate: null,
			updatedAt: input.now,
		});
		await insertActivity(executor, {
			groupId: input.groupId,
			actorUserId: input.actorUserId,
			action: "recurring.paused",
			entityType: "recurring_expense",
			entityId: row.id,
			summary: row.description,
			after: { pauseReason: "member_invalid", memberId: input.memberId },
			createdAt: input.now,
		});
		pausedCount += 1;
	}
	return pausedCount;
}

export async function advanceStaleRecurringDatesOnUnarchive(
	executor: DbExecutor,
	input: { groupId: string; now: Date },
): Promise<void> {
	const activeRows = await listActiveRecurringExpensesInGroup(
		executor,
		input.groupId,
	);
	const todayVN = todayInVietnam(input.now);
	for (const row of activeRows) {
		if (row.nextDueDate >= todayVN) continue;
		const nextDueDate = computeNextDueDate(
			toRecurringSchedule({
				frequency: row.frequency,
				dayOfWeek: row.dayOfWeek,
				dayOfMonth: row.dayOfMonth,
				monthOfYear: row.monthOfYear,
			}),
			todayVN,
			true,
		);
		await updateRecurringExpense(executor, input.groupId, row.id, {
			nextDueDate,
			updatedAt: input.now,
		});
	}
}

export async function hasMemberRecurringReferences(
	executor: DbExecutor,
	groupId: string,
	memberId: string,
): Promise<boolean> {
	const rows = await listGroupRecurringRowsForMemberCheck(executor, groupId);
	for (const row of rows) {
		const payers = z
			.array(RecurringPayerTemplateEntry)
			.parse(row.payersTemplate);
		const split = SplitInput.parse(row.splitTemplate);
		if (
			payers.some((p) => p.memberId === memberId) ||
			splitTemplateMemberIds(split).includes(memberId)
		) {
			return true;
		}
	}
	return false;
}
