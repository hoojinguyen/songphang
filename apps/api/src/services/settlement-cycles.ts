import { z } from "@hono/zod-openapi";
import {
	type CreateSettlementCycleRequest,
	MemberColorCode,
	MemberShapeCode,
	SettlementCycleDto,
	SettlementCycleResponse,
	SettlementCyclesResponse,
} from "@songphang/contract";
import {
	countCurrentPeriodStats,
	type DbExecutor,
	deleteSettlementCycle,
	findGroup,
	findLatestSettlementCycle,
	findSettlementCycle,
	findUserById,
	fundCashAndContributions,
	insertActivity,
	insertSettlementCycle,
	listGroupMembers,
	listSettlementCycles,
	lockGroup,
	stampOpenCountedTransactionsToCycle,
	suggestGroupTransfers,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { getGroupAccess } from "../auth/group-access.js";
import { AppError } from "../errors.js";
import { assertGroupRowNotArchived } from "./group-guards.js";

export function toSettlementCycleDto(row: {
	id: string;
	cycleNumber: number;
	title: string;
	startedAt: Date;
	closedAt: Date;
	closedBy: string | null;
	closedByName: string | null;
	expenseCount: number;
	totalExpenseAmount: number;
	snapshot: unknown;
}): SettlementCycleDto {
	return SettlementCycleDto.parse({
		id: row.id,
		cycleNumber: row.cycleNumber,
		title: row.title,
		startedAt: row.startedAt.toISOString(),
		closedAt: row.closedAt.toISOString(),
		closedBy:
			row.closedBy && row.closedByName
				? { id: row.closedBy, name: row.closedByName }
				: null,
		expenseCount: row.expenseCount,
		totalExpenseAmount: row.totalExpenseAmount,
		snapshot: row.snapshot,
	});
}

export async function getSettlementCyclesIn(
	executor: DbExecutor,
	groupId: string,
) {
	const [group, cycleRows, stats] = await Promise.all([
		findGroup(executor, groupId),
		listSettlementCycles(executor, groupId),
		countCurrentPeriodStats(executor, groupId),
	]);
	if (group === null) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	const latest = cycleRows[0] ?? null;
	const startedAt = latest ? latest.closedAt : group.createdAt;
	return SettlementCyclesResponse.parse({
		cycles: cycleRows.map(toSettlementCycleDto),
		currentPeriod: {
			startedAt: startedAt.toISOString(),
			expenseCount: stats.expenseCount,
			totalExpenseAmount: stats.totalExpenseAmount,
			countedTransactionCount: stats.countedTransactionCount,
		},
	});
}

export async function getSettlementCycles(deps: AppDeps, groupId: string) {
	return deps.db.transaction(
		(executor) => getSettlementCyclesIn(executor, groupId),
		{ isolationLevel: "repeatable read", accessMode: "read only" },
	);
}

export async function createSettlementCycle(
	executor: DbExecutor,
	input: {
		groupId: string;
		userId: string;
		request: CreateSettlementCycleRequest;
		now: Date;
	},
) {
	const locked = await lockGroup(executor, input.groupId);
	await getGroupAccess(executor, {
		groupId: input.groupId,
		userId: input.userId,
		minimumRole: "editor",
	});
	assertGroupRowNotArchived(locked);

	const stats = await countCurrentPeriodStats(executor, input.groupId);
	if (stats.countedTransactionCount === 0) {
		throw new AppError(
			422,
			"CYCLE_EMPTY",
			"Current period has no counted transactions",
		);
	}

	const [group, latestCycle, members, fund, actor] = await Promise.all([
		findGroup(executor, input.groupId),
		findLatestSettlementCycle(executor, input.groupId),
		listGroupMembers(executor, input.groupId),
		fundCashAndContributions(executor, input.groupId),
		findUserById(executor, input.userId),
	]);
	if (group === null) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	const { balances, transfers } = await suggestGroupTransfers(executor, {
		groupId: input.groupId,
		minimizeDebts: group.minimizeDebts,
	});
	const memberById = new Map(members.map((member) => [member.id, member]));
	const personBalances = balances
		.map((entry) => {
			const member = memberById.get(entry.memberId);
			if (member?.kind !== "person") return null;
			return {
				memberId: member.id,
				name: member.name,
				shape: MemberShapeCode.parse(member.shape),
				color: MemberColorCode.parse(member.color),
				balance: entry.balance,
			};
		})
		.filter((entry): entry is NonNullable<typeof entry> => entry !== null);

	const snapshot = {
		balances: personBalances,
		transfers: transfers.map((transfer) => {
			const from = memberById.get(transfer.fromMemberId);
			const to = memberById.get(transfer.toMemberId);
			if (!from || !to) throw new Error("Settlement member not found");
			return {
				fromMemberId: from.id,
				fromName: from.name,
				toMemberId: to.id,
				toName: to.name,
				amount: transfer.amount,
			};
		}),
		fundBalance: fund ? fund.cash : null,
	};

	const cycleNumber = (latestCycle?.cycleNumber ?? 0) + 1;
	const startedAt = latestCycle ? latestCycle.closedAt : group.createdAt;
	const closedAt =
		input.now.getTime() >= startedAt.getTime() ? input.now : startedAt;
	const title = input.request.title ?? `Đợt ${cycleNumber}`;

	const inserted = await insertSettlementCycle(executor, {
		groupId: input.groupId,
		cycleNumber,
		title,
		startedAt,
		closedAt,
		closedBy: input.userId,
		expenseCount: stats.expenseCount,
		totalExpenseAmount: stats.totalExpenseAmount,
		snapshot,
		createdAt: input.now,
	});

	await stampOpenCountedTransactionsToCycle(
		executor,
		input.groupId,
		inserted.id,
	);

	await insertActivity(executor, {
		groupId: input.groupId,
		actorUserId: input.userId,
		action: "cycle.closed",
		entityType: "group",
		entityId: input.groupId,
		summary: title,
		after: {
			cycleId: inserted.id,
			cycleNumber,
			expenseCount: stats.expenseCount,
			totalExpenseAmount: stats.totalExpenseAmount,
		},
		createdAt: input.now,
	});

	return SettlementCycleResponse.parse({
		cycle: toSettlementCycleDto({
			...inserted,
			closedByName: actor?.name ?? null,
		}),
	});
}

export async function reopenSettlementCycle(
	deps: AppDeps,
	input: { groupId: string; userId: string; cycleId: string },
): Promise<void> {
	if (!z.uuid().safeParse(input.cycleId).success) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	await deps.db.transaction(async (executor) => {
		const locked = await lockGroup(executor, input.groupId);
		await getGroupAccess(executor, {
			groupId: input.groupId,
			userId: input.userId,
			minimumRole: "owner",
		});
		assertGroupRowNotArchived(locked);

		const [target, latest] = await Promise.all([
			findSettlementCycle(executor, input.groupId, input.cycleId),
			findLatestSettlementCycle(executor, input.groupId),
		]);
		if (target === null) {
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		}
		if (latest === null || latest.id !== target.id) {
			throw new AppError(
				409,
				"CYCLE_NOT_LATEST",
				"Only the latest settlement cycle can be reopened",
			);
		}

		await deleteSettlementCycle(executor, input.groupId, target.id);
		await insertActivity(executor, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: "cycle.reopened",
			entityType: "group",
			entityId: input.groupId,
			summary: target.title,
			before: {
				cycleId: target.id,
				cycleNumber: target.cycleNumber,
			},
			createdAt: deps.now(),
		});
	});
	deps.events.publishChanged(input.groupId, [
		"group",
		"transactions",
		"activity",
		"settlementCycles",
	]);
}
