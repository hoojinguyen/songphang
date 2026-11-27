import { z } from "@hono/zod-openapi";
import {
	type CreateHouseholdRequest,
	HouseholdResponse,
	HouseholdsResponse,
	type UpdateHouseholdRequest,
} from "@songphang/contract";
import {
	countGroupHouseholds,
	type DbExecutor,
	deleteHousehold,
	findHousehold,
	insertActivity,
	insertHousehold,
	listGroupHouseholds,
	listGroupMembers,
	lockGroup,
	setHouseholdMembers,
	updateHousehold,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { getGroupAccess } from "../auth/group-access.js";
import { AppError } from "../errors.js";
import { assertGroupRowNotArchived } from "./group-guards.js";

const MAX_HOUSEHOLDS_PER_GROUP = 30;

function toHouseholdDto(row: {
	id: string;
	name: string;
	representativeMemberId: string;
	memberIds: string[];
	createdAt: Date;
	updatedAt: Date;
}) {
	return {
		id: row.id,
		name: row.name,
		representativeMemberId: row.representativeMemberId,
		memberIds: row.memberIds,
		createdAt: row.createdAt.toISOString(),
		updatedAt: row.updatedAt.toISOString(),
	};
}

function validateHouseholdMembers(input: {
	members: Awaited<ReturnType<typeof listGroupMembers>>;
	memberIds: string[];
	representativeMemberId: string;
	currentHouseholdId?: string;
}) {
	if (!input.memberIds.includes(input.representativeMemberId)) {
		throw new AppError(
			400,
			"VALIDATION_FAILED",
			"Representative must belong to the household",
		);
	}
	const memberById = new Map(input.members.map((m) => [m.id, m]));
	for (const memberId of input.memberIds) {
		const member = memberById.get(memberId);
		if (!member) {
			throw new AppError(
				400,
				"MEMBER_NOT_IN_GROUP",
				"Member does not belong to group",
			);
		}
		if (member.kind !== "person") {
			throw new AppError(
				400,
				"VALIDATION_FAILED",
				"Households can only contain person members",
			);
		}
		if (
			member.householdId !== null &&
			member.householdId !== input.currentHouseholdId
		) {
			throw new AppError(
				409,
				"HOUSEHOLD_MEMBER_CONFLICT",
				"Member already belongs to another household",
			);
		}
	}
	const representative = memberById.get(input.representativeMemberId);
	if (!representative?.active) {
		throw new AppError(
			400,
			"VALIDATION_FAILED",
			"Household representative must be active",
		);
	}
}

export async function listHouseholds(deps: AppDeps, groupId: string) {
	return deps.db.transaction(
		async (executor) => {
			const rows = await listGroupHouseholds(executor, groupId);
			return HouseholdsResponse.parse({
				households: rows.map(toHouseholdDto),
			});
		},
		{ isolationLevel: "repeatable read", accessMode: "read only" },
	);
}

export async function createHousehold(
	executor: DbExecutor,
	input: {
		groupId: string;
		userId: string;
		request: CreateHouseholdRequest;
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

	const count = await countGroupHouseholds(executor, input.groupId);
	if (count >= MAX_HOUSEHOLDS_PER_GROUP) {
		throw new AppError(
			422,
			"LIMIT_REACHED",
			"Group has reached the household limit",
		);
	}

	const members = await listGroupMembers(executor, input.groupId);
	validateHouseholdMembers({
		members,
		memberIds: input.request.memberIds,
		representativeMemberId: input.request.representativeMemberId,
	});

	const created = await insertHousehold(executor, {
		groupId: input.groupId,
		name: input.request.name,
		representativeMemberId: input.request.representativeMemberId,
		now: input.now,
	});
	await setHouseholdMembers(executor, {
		groupId: input.groupId,
		householdId: created.id,
		memberIds: input.request.memberIds,
		now: input.now,
	});

	const saved = await findHousehold(executor, input.groupId, created.id);
	if (saved === null) throw new Error("Created household missing");
	await insertActivity(executor, {
		groupId: input.groupId,
		actorUserId: input.userId,
		action: "household.created",
		entityType: "household",
		entityId: saved.id,
		summary: saved.name,
		after: {
			name: saved.name,
			representativeMemberId: saved.representativeMemberId,
			memberIds: saved.memberIds,
		},
		createdAt: input.now,
	});
	return HouseholdResponse.parse({ household: toHouseholdDto(saved) });
}

export async function editHousehold(
	deps: AppDeps,
	input: {
		groupId: string;
		userId: string;
		householdId: string;
		request: UpdateHouseholdRequest;
	},
) {
	if (!z.uuid().safeParse(input.householdId).success) {
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

		const before = await findHousehold(
			executor,
			input.groupId,
			input.householdId,
		);
		if (before === null) {
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		}
		const nextName = input.request.name ?? before.name;
		const nextMemberIds = input.request.memberIds ?? before.memberIds;
		const nextRepresentative =
			input.request.representativeMemberId ?? before.representativeMemberId;

		const members = await listGroupMembers(executor, input.groupId);
		validateHouseholdMembers({
			members,
			memberIds: nextMemberIds,
			representativeMemberId: nextRepresentative,
			currentHouseholdId: before.id,
		});

		const now = deps.now();
		await updateHousehold(executor, {
			groupId: input.groupId,
			householdId: before.id,
			changes: {
				name: nextName,
				representativeMemberId: nextRepresentative,
				updatedAt: now,
			},
		});
		if (input.request.memberIds !== undefined) {
			await setHouseholdMembers(executor, {
				groupId: input.groupId,
				householdId: before.id,
				memberIds: nextMemberIds,
				now,
			});
		}

		const after = await findHousehold(executor, input.groupId, before.id);
		if (after === null) throw new Error("Updated household missing");
		await insertActivity(executor, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: "household.updated",
			entityType: "household",
			entityId: after.id,
			summary: after.name,
			before: {
				name: before.name,
				representativeMemberId: before.representativeMemberId,
				memberIds: before.memberIds,
			},
			after: {
				name: after.name,
				representativeMemberId: after.representativeMemberId,
				memberIds: after.memberIds,
			},
			createdAt: now,
		});
		return HouseholdResponse.parse({ household: toHouseholdDto(after) });
	});
	deps.events.publishChanged(input.groupId, [
		"members",
		"balances",
		"households",
		"activity",
	]);
	return result;
}

export async function removeHousehold(
	deps: AppDeps,
	input: { groupId: string; userId: string; householdId: string },
) {
	if (!z.uuid().safeParse(input.householdId).success) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	await deps.db.transaction(async (executor) => {
		const group = await lockGroup(executor, input.groupId);
		await getGroupAccess(executor, {
			groupId: input.groupId,
			userId: input.userId,
			minimumRole: "editor",
		});
		assertGroupRowNotArchived(group);

		const before = await findHousehold(
			executor,
			input.groupId,
			input.householdId,
		);
		if (before === null) {
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		}
		const now = deps.now();
		await deleteHousehold(executor, input.groupId, before.id);
		await insertActivity(executor, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: "household.deleted",
			entityType: "household",
			entityId: before.id,
			summary: before.name,
			before: {
				name: before.name,
				representativeMemberId: before.representativeMemberId,
				memberIds: before.memberIds,
			},
			createdAt: now,
		});
	});
	deps.events.publishChanged(input.groupId, [
		"members",
		"balances",
		"households",
		"activity",
	]);
}
