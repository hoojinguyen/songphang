import { randomBytes } from "node:crypto";
import {
	type CreateGroupRequest,
	GroupResponse,
	GroupsResponse,
	nextMemberAppearance,
	type UpdateGroupRequest,
	type UserDto,
} from "@songphang/contract";
import {
	type DbExecutor,
	findGroup,
	findGroupAccess,
	insertActivity,
	insertGroup,
	insertGroupUser,
	insertMember,
	listBalancesForGroups,
	listMembersForGroups,
	listUserGroups,
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
	const group = await findGroup(executor, groupId);
	const access = await findGroupAccess(executor, groupId, userId);
	if (group === null || access === null)
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	return GroupResponse.parse({
		group: {
			...group,
			role: access.role,
			myMemberId: access.memberId,
			createdAt: group.createdAt.toISOString(),
		},
	});
}
export async function createGroup(
	executor: DbExecutor,
	input: { request: CreateGroupRequest; user: UserDto; now: Date },
) {
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
		createdAt: input.now,
	});
	return getGroup(executor, group.id, input.user.id);
}
export async function listGroups(deps: AppDeps, userId: string) {
	const groups = await listUserGroups(deps.db, userId);
	const ids = groups.map((group) => group.id);
	const [members, balances] = await Promise.all([
		listMembersForGroups(deps.db, ids),
		listBalancesForGroups(deps.db, ids),
	]);
	return GroupsResponse.parse({
		groups: groups.map((group) => ({
			id: group.id,
			name: group.name,
			currency: group.currency,
			memberCount: members.filter((member) => member.groupId === group.id)
				.length,
			previewMembers: members
				.filter((member) => member.groupId === group.id)
				.slice(0, 4),
			myBalance:
				balances.find((balance) => balance.memberId === group.memberId)
					?.balance ?? 0,
		})),
	});
}
export async function editGroup(
	deps: AppDeps,
	input: { groupId: string; userId: string; changes: UpdateGroupRequest },
) {
	return deps.db.transaction(async (transaction) => {
		await lockGroup(transaction, input.groupId);
		const before = await getGroup(transaction, input.groupId, input.userId);
		await updateGroup(transaction, {
			groupId: input.groupId,
			changes: {
				...(input.changes.name === undefined
					? {}
					: { name: input.changes.name }),
				...(input.changes.minimizeDebts === undefined
					? {}
					: { minimizeDebts: input.changes.minimizeDebts }),
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
}
