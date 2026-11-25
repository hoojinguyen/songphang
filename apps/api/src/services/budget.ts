import { BudgetResponse, type PutBudgetRequest } from "@songphang/contract";
import {
	budgetState,
	currentMonthRange,
	localDateRangeToUtc,
} from "@songphang/core";
import {
	type DbExecutor,
	deleteBudget,
	findBudget,
	insertActivity,
	lockGroup,
	sumSpent,
	upsertBudget,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { getGroupAccess } from "../auth/group-access.js";
import { assertGroupRowNotArchived } from "./group-guards.js";

export function budgetRangeFor(period: "month" | "total", now: Date) {
	if (period === "total") {
		return { periodStart: null, periodEnd: null, utcRange: {} };
	}
	const range = currentMonthRange(now);
	return {
		periodStart: range.start,
		periodEnd: range.end,
		utcRange: localDateRangeToUtc(range.start, range.end),
	};
}

async function readBudget(executor: DbExecutor, groupId: string, now: Date) {
	const row = await findBudget(executor, groupId);
	if (row === null) return BudgetResponse.parse({ budget: null });
	const period = row.period === "total" ? "total" : "month";
	const { periodStart, periodEnd, utcRange } = budgetRangeFor(period, now);
	const spent = await sumSpent(executor, groupId, utcRange);
	return BudgetResponse.parse({
		budget: {
			period,
			amount: row.amount,
			spent,
			state: budgetState(spent, row.amount),
			periodStart,
			periodEnd,
		},
	});
}

export async function getBudget(deps: AppDeps, groupId: string) {
	return deps.db.transaction(
		(executor) => readBudget(executor, groupId, deps.now()),
		{ isolationLevel: "repeatable read", accessMode: "read only" },
	);
}

export async function putBudget(
	deps: AppDeps,
	input: { groupId: string; userId: string; request: PutBudgetRequest },
) {
	const now = deps.now();
	const response = await deps.db.transaction(async (executor) => {
		const lockedGroup = await lockGroup(executor, input.groupId);
		await getGroupAccess(executor, { ...input, minimumRole: "owner" });
		assertGroupRowNotArchived(lockedGroup);
		const before = await findBudget(executor, input.groupId);
		await upsertBudget(executor, {
			groupId: input.groupId,
			period: input.request.period,
			amount: input.request.amount,
			updatedBy: input.userId,
			now,
		});
		await insertActivity(executor, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: "update",
			entityType: "group",
			entityId: input.groupId,
			summary: "Budget",
			before: before ? { period: before.period, amount: before.amount } : null,
			after: { period: input.request.period, amount: input.request.amount },
			createdAt: now,
		});
		return readBudget(executor, input.groupId, now);
	});
	deps.events.publishChanged(input.groupId, ["budget", "activity"]);
	return response;
}

export async function removeBudget(
	deps: AppDeps,
	input: { groupId: string; userId: string },
) {
	const now = deps.now();
	await deps.db.transaction(async (executor) => {
		const lockedGroup = await lockGroup(executor, input.groupId);
		await getGroupAccess(executor, { ...input, minimumRole: "owner" });
		assertGroupRowNotArchived(lockedGroup);
		const before = await findBudget(executor, input.groupId);
		if (before === null) return;
		await deleteBudget(executor, input.groupId);
		await insertActivity(executor, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: "update",
			entityType: "group",
			entityId: input.groupId,
			summary: "Budget",
			before: { period: before.period, amount: before.amount },
			after: null,
			createdAt: now,
		});
	});
	deps.events.publishChanged(input.groupId, ["budget", "activity"]);
}
