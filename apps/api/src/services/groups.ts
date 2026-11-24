import { randomBytes } from "node:crypto";
import {
	type CreateGroupRequest,
	type DeleteGroupRequest,
	GroupResponse,
	GroupsResponse,
	JOB_NAMES,
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
	insertGroup,
	insertGroupUser,
	insertMember,
	isAppleDeletionPending,
	listBalancesForGroups,
	listGroupAttachmentKeys,
	listMembersForGroups,
	listUserGroups,
	lockAccount,
	lockGroup,
	updateGroup,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { AppError } from "../errors.js";
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
			createdAt: group.createdAt.toISOString(),
		},
	});
}
export async function createGroup(
	executor: DbExecutor,
	input: { request: CreateGroupRequest; user: UserDto; now: Date },
) {
	const [account] = await lockAccount(executor, input.user.id);
	if (!account) {
		throw new AppError(401, "UNAUTHENTICATED", "Authentication required");
	}
	const appleIdentity = await findUserAppleIdentity(executor, input.user.id);
	if (isAppleDeletionPending(appleIdentity?.providerSecret)) {
		throw new AppError(403, "FORBIDDEN", "Account is undergoing deletion");
	}
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
export async function listGroups(deps: AppDeps, userId: string) {
	return deps.db.transaction(
		async (executor) => {
			const groups = await listUserGroups(executor, userId);
			const ids = groups.map((group) => group.id);
			const [members, balances] = await Promise.all([
				listMembersForGroups(executor, ids),
				listBalancesForGroups(executor, ids),
			]);
			return GroupsResponse.parse({
				groups: groups.map((group) => ({
					id: group.id,
					name: group.name,
					currency: group.currency,
					memberCount: members.filter(
						(member) => member.groupId === group.id && member.kind === "person",
					).length,
					previewMembers: members
						.filter(
							(member) =>
								member.groupId === group.id && member.kind === "person",
						)
						.slice(0, 4),
					myBalance:
						balances.find((balance) => balance.memberId === group.memberId)
							?.balance ?? 0,
				})),
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
		await lockGroup(transaction, input.groupId);
		const before = await getGroup(transaction, input.groupId, input.userId);
		if (before.group.role !== "owner")
			throw new AppError(403, "FORBIDDEN", "Insufficient group role");
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
