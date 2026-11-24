import { randomBytes } from "node:crypto";
import {
	type CloneGroupRequest,
	type CreateGroupRequest,
	type DeleteGroupRequest,
	GroupResponse,
	type GroupStatusFilter,
	GroupsResponse,
	JOB_NAMES,
	MemberColorCode,
	MemberShapeCode,
	nextMemberAppearance,
	type UpdateGroupRequest,
	type UserDto,
} from "@songphang/contract";
import {
	type DbExecutor,
	deleteGroupRow,
	findGroup,
	findGroupAccess,
	findGroupOwner,
	findUserAppleIdentity,
	insertActivity,
	insertCategories,
	insertGroup,
	insertGroupUser,
	insertMember,
	insertPaymentMethods,
	isAppleDeletionPending,
	listBalancesForGroups,
	listGroupAttachmentKeys,
	listGroupCategories,
	listMembersForGroups,
	listPaymentMethodsByGroup,
	listPendingApprovalsForGroups,
	listPendingSettlementsForGroups,
	listPeople,
	listUserGroups,
	lockAccount,
	lockGroup,
	updateGroup,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { getGroupAccess } from "../auth/group-access.js";
import { AppError } from "../errors.js";
import { assertGroupRowNotArchived } from "./group-guards.js";
import { collectPendingActions } from "./pending-actions.js";

async function assertAccountWritable(executor: DbExecutor, userId: string) {
	const [account] = await lockAccount(executor, userId);
	if (!account) {
		throw new AppError(401, "UNAUTHENTICATED", "Authentication required");
	}
	const appleIdentity = await findUserAppleIdentity(executor, userId);
	if (isAppleDeletionPending(appleIdentity?.providerSecret)) {
		throw new AppError(403, "FORBIDDEN", "Account is undergoing deletion");
	}
}

export async function getGroup(
	executor: DbExecutor,
	groupId: string,
	userId: string,
) {
	const [group, access, owner] = await Promise.all([
		findGroup(executor, groupId),
		findGroupAccess(executor, groupId, userId),
		findGroupOwner(executor, groupId),
	]);
	if (group === null || access === null)
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	return GroupResponse.parse({
		group: {
			...group,
			ownerName: owner?.name ?? "",
			role: access.role,
			myMemberId: access.memberId,
			muted: access.muted,
			archivedAt: group.archivedAt?.toISOString() ?? null,
			createdAt: group.createdAt.toISOString(),
		},
	});
}

export async function createGroup(
	executor: DbExecutor,
	input: { request: CreateGroupRequest; user: UserDto; now: Date },
) {
	await assertAccountWritable(executor, input.user.id);
	const group = await insertGroup(executor, {
		name: input.request.name,
		createdBy: input.user.id,
		inviteToken: randomBytes(32).toString("base64url"),
		createdAt: input.now,
		updatedAt: input.now,
	});
	const appearances: Array<ReturnType<typeof nextMemberAppearance>> = [];
	let ownerMemberId: string | null = null;
	for (const [position, name] of [
		input.user.name,
		...input.request.memberNames,
	].entries()) {
		const appearance = nextMemberAppearance(appearances, position);
		appearances.push(appearance);
		const member = await insertMember(executor, {
			groupId: group.id,
			name,
			position,
			...appearance,
			createdAt: input.now,
			updatedAt: input.now,
		});
		if (position === 0) ownerMemberId = member.id;
	}
	await insertGroupUser(executor, {
		groupId: group.id,
		userId: input.user.id,
		memberId: ownerMemberId,
		role: "owner",
		createdAt: input.now,
	});
	await insertActivity(executor, {
		groupId: group.id,
		actorUserId: input.user.id,
		action: "create",
		entityType: "group",
		entityId: group.id,
		summary: input.request.name,
		after: { memberCount: input.request.memberNames.length + 1 },
		createdAt: input.now,
	});
	return getGroup(executor, group.id, input.user.id);
}

export async function listGroups(
	deps: AppDeps,
	userId: string,
	status: GroupStatusFilter = "all",
) {
	return deps.db.transaction(
		async (executor) => {
			const groups = await listUserGroups(executor, userId, status);
			const ids = groups.map((group) => group.id);
			const activeIds = groups
				.filter((group) => group.archivedAt === null)
				.map((group) => group.id);
			const [members, balances, pendingSettlements, pendingApprovals] =
				await Promise.all([
					listMembersForGroups(executor, ids),
					listBalancesForGroups(executor, ids),
					listPendingSettlementsForGroups(executor, activeIds),
					listPendingApprovalsForGroups(executor, activeIds),
				]);
			const pending = collectPendingActions({
				groups,
				members,
				pendingSettlements,
				pendingApprovals,
			});
			return GroupsResponse.parse({
				groups: groups.map((group) => {
					const people = members.filter(
						(member) => member.groupId === group.id && member.kind === "person",
					);
					return {
						id: group.id,
						name: group.name,
						currency: group.currency,
						memberCount: people.length,
						previewMembers: people.slice(0, 4),
						myBalance:
							balances.find((balance) => balance.memberId === group.memberId)
								?.balance ?? 0,
						archivedAt: group.archivedAt?.toISOString() ?? null,
						role: group.role,
						pendingActionCount: pending.countByGroupId.get(group.id) ?? 0,
					};
				}),
			});
		},
		{ isolationLevel: "repeatable read", accessMode: "read only" },
	);
}

export async function editGroup(
	deps: AppDeps,
	input: { groupId: string; userId: string; changes: UpdateGroupRequest },
) {
	const result = await deps.db.transaction(async (transaction) => {
		const locked = await lockGroup(transaction, input.groupId);
		const before = await getGroup(transaction, input.groupId, input.userId);
		if (before.group.role !== "owner")
			throw new AppError(403, "FORBIDDEN", "Insufficient group role");
		assertGroupRowNotArchived(locked);
		await updateGroup(transaction, {
			groupId: input.groupId,
			changes: {
				...(input.changes.defaultRole === undefined
					? {}
					: { defaultRole: input.changes.defaultRole }),
				...(input.changes.name === undefined
					? {}
					: { name: input.changes.name }),
				...(input.changes.minimizeDebts === undefined
					? {}
					: { minimizeDebts: input.changes.minimizeDebts }),
				...(input.changes.reminderIntervalDays === undefined
					? {}
					: { reminderIntervalDays: input.changes.reminderIntervalDays }),
				...(input.changes.approvalThreshold === undefined
					? {}
					: { approvalThreshold: input.changes.approvalThreshold }),
			},
			now: deps.now(),
		});
		const after = await getGroup(transaction, input.groupId, input.userId);
		const keys = Object.keys(input.changes);
		await insertActivity(transaction, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: "update",
			entityType: "group",
			entityId: input.groupId,
			summary: after.group.name,
			before: Object.fromEntries(
				Object.entries(before.group).filter(([key]) => keys.includes(key)),
			),
			after: input.changes,
			createdAt: deps.now(),
		});
		return after;
	});
	deps.events.publishChanged(input.groupId, ["group", "balances", "activity"]);
	return result;
}

export async function setGroupArchived(
	deps: AppDeps,
	input: { groupId: string; userId: string; archived: boolean },
) {
	let changed = false;
	const result = await deps.db.transaction(async (transaction) => {
		const locked = await lockGroup(transaction, input.groupId);
		const current = await getGroup(transaction, input.groupId, input.userId);
		if (current.group.role !== "owner") {
			throw new AppError(403, "FORBIDDEN", "Insufficient group role");
		}
		if (locked === null) {
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		}
		const alreadyMatches = input.archived
			? locked.archivedAt !== null
			: locked.archivedAt === null;
		if (alreadyMatches) {
			return current;
		}
		const now = deps.now();
		await updateGroup(transaction, {
			groupId: input.groupId,
			changes: { archivedAt: input.archived ? now : null },
			now,
		});
		await insertActivity(transaction, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: input.archived ? "group.archived" : "group.unarchived",
			entityType: "group",
			entityId: input.groupId,
			summary: current.group.name,
			createdAt: now,
		});
		changed = true;
		return getGroup(transaction, input.groupId, input.userId);
	});
	if (changed) {
		deps.events.publishChanged(input.groupId, ["group", "activity"]);
	}
	return result;
}

async function cloneActivePeople(
	executor: DbExecutor,
	input: {
		sourceGroupId: string;
		newGroupId: string;
		callerMemberId: string | null;
		userName: string;
		now: Date;
	},
) {
	const activePeople = (await listPeople(executor, input.sourceGroupId)).filter(
		(member) => member.active,
	);
	const memberIdMap = new Map<string, string>();
	let ownerMemberId: string | null = null;
	const callerInActive = activePeople.some(
		(member) => member.id === input.callerMemberId,
	);

	if (!callerInActive) {
		const appearances = activePeople.map((member) => ({
			shape: MemberShapeCode.parse(member.shape),
			color: MemberColorCode.parse(member.color),
		}));
		const callerAppearance = nextMemberAppearance(appearances, 0);
		const inserted = await insertMember(executor, {
			groupId: input.newGroupId,
			name: input.userName,
			position: 0,
			...callerAppearance,
			createdAt: input.now,
			updatedAt: input.now,
		});
		ownerMemberId = inserted.id;
	}

	for (const [index, source] of activePeople.entries()) {
		const inserted = await insertMember(executor, {
			groupId: input.newGroupId,
			name: source.name,
			kind: "person",
			active: true,
			defaultWeight: source.defaultWeight,
			position: index + 1,
			shape: source.shape,
			color: source.color,
			createdAt: input.now,
			updatedAt: input.now,
		});
		memberIdMap.set(source.id, inserted.id);
		if (source.id === input.callerMemberId) {
			ownerMemberId = inserted.id;
		}
	}

	return {
		ownerMemberId,
		memberIdMap,
		memberCount: activePeople.length + (callerInActive ? 0 : 1),
	};
}

export async function cloneGroup(
	executor: DbExecutor,
	input: {
		sourceGroupId: string;
		request: CloneGroupRequest;
		user: UserDto;
		now: Date;
	},
) {
	await assertAccountWritable(executor, input.user.id);
	await lockGroup(executor, input.sourceGroupId);
	const access = await getGroupAccess(executor, {
		groupId: input.sourceGroupId,
		userId: input.user.id,
		minimumRole: "editor",
	});
	const source = await findGroup(executor, input.sourceGroupId);
	if (source === null) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	const newGroup = await insertGroup(executor, {
		name: input.request.name,
		minimizeDebts: source.minimizeDebts,
		defaultRole: source.defaultRole,
		createdBy: input.user.id,
		inviteToken: randomBytes(32).toString("base64url"),
		archivedAt: null,
		createdAt: input.now,
		updatedAt: input.now,
	});
	const { ownerMemberId, memberIdMap, memberCount } = await cloneActivePeople(
		executor,
		{
			sourceGroupId: input.sourceGroupId,
			newGroupId: newGroup.id,
			callerMemberId: access.memberId,
			userName: input.user.name,
			now: input.now,
		},
	);
	await insertGroupUser(executor, {
		groupId: newGroup.id,
		userId: input.user.id,
		memberId: ownerMemberId,
		role: "owner",
		createdAt: input.now,
	});
	if (input.request.copyPaymentMethods && memberIdMap.size > 0) {
		const methodsByMember = await listPaymentMethodsByGroup(
			executor,
			input.sourceGroupId,
		);
		const rows = [...memberIdMap.entries()].flatMap(([sourceId, targetId]) =>
			(methodsByMember.get(sourceId) ?? []).map((method) => ({
				memberId: targetId,
				kind: method.kind,
				bankBin: method.bankBin,
				accountNumber: method.accountNumber,
				accountName: method.accountName,
				createdAt: input.now,
				updatedAt: input.now,
			})),
		);
		await insertPaymentMethods(executor, rows);
	}
	if (input.request.copyCategories) {
		const liveCategories = (
			await listGroupCategories(executor, input.sourceGroupId)
		).filter((category) => category.archivedAt === null);
		await insertCategories(
			executor,
			liveCategories.map((category) => ({
				groupId: newGroup.id,
				name: category.name,
				nameKey: category.nameKey,
				color: category.color,
				archivedAt: null,
				createdAt: input.now,
				updatedAt: input.now,
			})),
		);
	}
	await insertActivity(executor, {
		groupId: newGroup.id,
		actorUserId: input.user.id,
		action: "create",
		entityType: "group",
		entityId: newGroup.id,
		summary: input.request.name,
		after: { memberCount },
		createdAt: input.now,
	});
	return getGroup(executor, newGroup.id, input.user.id);
}

export async function deleteGroup(
	deps: AppDeps,
	input: { groupId: string; userId: string; request: DeleteGroupRequest },
) {
	await deps.db.transaction(async (tx) => {
		await lockGroup(tx, input.groupId);
		const current = await getGroup(tx, input.groupId, input.userId);
		if (current.group.role !== "owner")
			throw new AppError(403, "FORBIDDEN", "Insufficient group role");
		if (input.request.name !== current.group.name)
			throw new AppError(400, "VALIDATION_FAILED", "Group name does not match");
		const keys = await listGroupAttachmentKeys(tx, input.groupId);
		await deleteGroupRow(tx, input.groupId);
		for (let offset = 0; offset < keys.length; offset += 10_000) {
			await deps.enqueue(tx, JOB_NAMES.deleteFiles, {
				keys: keys.slice(offset, offset + 10_000),
			});
		}
	});
	deps.events.publishRemoved(input.groupId, null);
}
