import { randomBytes } from "node:crypto";
import {
	InvitePreviewResponse,
	InviteResponse,
	type JoinRequest,
} from "@songphang/contract";
import {
	type DbExecutor,
	findGroupAccess,
	findInvite,
	findMember,
	insertActivity,
	insertGroupUser,
	inviteGroupDetails,
	listMemberBalances,
	listPeople,
	lockAccount,
	lockGroup,
	readGroupInvite,
	setUserMember,
	updateGroupInvite,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { getGroupAccess } from "../auth/group-access.js";
import { AppError } from "../errors.js";
import { assertGroupRowNotArchived } from "./group-guards.js";
import { getGroup } from "./groups.js";
import { addGroupMember } from "./members.js";

async function validInvite(executor: DbExecutor, token: string) {
	const group = await findInvite(executor, token);
	if (!group?.active)
		throw new AppError(404, "INVITE_INVALID", "Invite is invalid");
	return group;
}
export async function previewInvite(
	deps: AppDeps,
	input: { token: string; userId: string },
) {
	return deps.db.transaction(async (tx) => {
		const group = await validInvite(tx, input.token);
		const [members, balances, details, access] = await Promise.all([
			listPeople(tx, group.id),
			listMemberBalances(tx, group.id),
			inviteGroupDetails(tx, group.id),
			findGroupAccess(tx, group.id, input.userId),
		]);
		return InvitePreviewResponse.parse({
			group: { id: group.id, name: group.name },
			...details,
			memberCount: members.filter((m) => m.active).length,
			alreadyJoined: access !== null,
			members: members
				.filter((m) => m.active)
				.map((m) => ({
					...m,
					balance: m.claimed
						? null
						: (balances.find((b) => b.memberId === m.id)?.balance ?? 0),
				})),
		});
	});
}
async function claimableMember(
	executor: DbExecutor,
	input: { groupId: string; memberId: string },
) {
	const member = await findMember(executor, input.groupId, input.memberId);
	if (!member?.active || member.kind !== "person")
		throw new AppError(
			400,
			"MEMBER_NOT_IN_GROUP",
			"Member is not active in this group",
		);
	if (member.claimed)
		throw new AppError(
			409,
			"MEMBER_ALREADY_CLAIMED",
			"Member is already claimed",
		);
	return member;
}
export async function joinInvite(
	executor: DbExecutor,
	input: { token: string; userId: string; request: JoinRequest; now: Date },
) {
	await lockAccount(executor, input.userId);
	const initial = await validInvite(executor, input.token);
	const locked = await lockGroup(executor, initial.id);
	const group = await validInvite(executor, input.token);
	assertGroupRowNotArchived(locked);
	if (await findGroupAccess(executor, group.id, input.userId))
		return { groupId: group.id };
	const member =
		"memberId" in input.request
			? await claimableMember(executor, {
					groupId: group.id,
					memberId: input.request.memberId,
				})
			: (
					await addGroupMember(executor, {
						groupId: group.id,
						userId: input.userId,
						myMemberId: null,
						request: { name: input.request.newMemberName },
						now: input.now,
					})
				).member;
	await insertGroupUser(executor, {
		groupId: group.id,
		userId: input.userId,
		memberId: member.id,
		role: group.defaultRole,
		createdAt: input.now,
	});
	await insertActivity(executor, {
		groupId: group.id,
		actorUserId: input.userId,
		action: "join",
		entityType: "group_user",
		entityId: input.userId,
		summary: member.name,
		after: { memberId: member.id, name: member.name },
		createdAt: input.now,
	});
	return { groupId: group.id };
}
export async function getInvite(deps: AppDeps, groupId: string) {
	const invite = await readGroupInvite(deps.db, groupId);
	if (!invite) throw new AppError(404, "NOT_FOUND", "Resource not found");
	return InviteResponse.parse({
		invite: { ...invite, url: `${deps.config.webOrigin}/join/${invite.token}` },
	});
}
export async function changeInvite(
	deps: AppDeps,
	input: {
		groupId: string;
		userId: string;
		active?: boolean;
		rotate?: boolean;
	},
) {
	await deps.db.transaction(async (tx) => {
		const locked = await lockGroup(tx, input.groupId);
		await getGroupAccess(tx, { ...input, minimumRole: "owner" });
		assertGroupRowNotArchived(locked);
		await updateGroupInvite(tx, {
			groupId: input.groupId,
			...(input.active === undefined ? {} : { active: input.active }),
			...(input.rotate ? { token: randomBytes(32).toString("base64url") } : {}),
			now: deps.now(),
		});
		await insertActivity(tx, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: "update",
			entityType: "group",
			entityId: input.groupId,
			summary: input.rotate ? "Invite rotated" : "Invite status changed",
			after: input.rotate
				? { inviteRotated: true }
				: { inviteActive: input.active },
			createdAt: deps.now(),
		});
	});
	deps.events.publishChanged(input.groupId, ["group", "activity"]);
	return getInvite(deps, input.groupId);
}
export async function chooseMember(
	deps: AppDeps,
	input: { groupId: string; userId: string; memberId: string },
) {
	const result = await deps.db.transaction(async (tx) => {
		await lockAccount(tx, input.userId);
		const locked = await lockGroup(tx, input.groupId);
		const access = await findGroupAccess(tx, input.groupId, input.userId);
		if (!access) throw new AppError(404, "NOT_FOUND", "Resource not found");
		assertGroupRowNotArchived(locked);
		const member = await findMember(tx, input.groupId, input.memberId);
		if (access.memberId !== input.memberId) await claimableMember(tx, input);
		else if (!member?.active || member.kind !== "person")
			throw new AppError(
				400,
				"MEMBER_NOT_IN_GROUP",
				"Member is not active in this group",
			);
		await setUserMember(tx, input);
		await insertActivity(tx, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: "update",
			entityType: "group_user",
			entityId: input.userId,
			summary: "Member chosen",
			after: { memberId: member?.id, name: member?.name },
			createdAt: deps.now(),
		});
		return getGroup(tx, input.groupId, input.userId);
	});
	deps.events.publishChanged(input.groupId, [
		"users",
		"members",
		"group",
		"activity",
	]);
	return result;
}
