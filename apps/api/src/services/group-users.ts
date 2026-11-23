import {
	GroupUsersResponse,
	type UpdateGroupUserRequest,
} from "@songphang/contract";
import {
	type DbExecutor,
	deleteGroupUser,
	findGroupAccess,
	findUserAppleIdentity,
	insertActivity,
	listGroupUsers,
	lockAccount,
	lockGroup,
	updateGroupUserRole,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { AppError } from "../errors.js";
import { getGroup } from "./groups.js";

type UserOperation = { groupId: string; userId: string; targetId: string };
async function groupUser(
	executor: DbExecutor,
	input: { groupId: string; userId: string },
) {
	const user = await findGroupAccess(executor, input.groupId, input.userId);
	if (!user) throw new AppError(404, "NOT_FOUND", "Resource not found");
	return user;
}
async function ownerAndTarget(executor: DbExecutor, input: UserOperation) {
	const actor = await groupUser(executor, input);
	if (actor.role !== "owner")
		throw new AppError(403, "FORBIDDEN", "Insufficient group role");
	const access = await groupUser(executor, {
		groupId: input.groupId,
		userId: input.targetId,
	});
	const target = (await listGroupUsers(executor, input.groupId)).find(
		(u) => u.userId === input.targetId,
	);
	return { ...access, name: target?.name ?? null };
}
export async function getGroupUsers(
	deps: AppDeps,
	input: { groupId: string; userId: string },
) {
	const users = await listGroupUsers(deps.db, input.groupId);
	return GroupUsersResponse.parse({
		users: users.map((user) => ({
			...user,
			isMe: user.userId === input.userId,
		})),
	});
}
export async function changeGroupUser(
	deps: AppDeps,
	input: UserOperation & { request: UpdateGroupUserRequest },
) {
	await deps.db.transaction(async (tx) => {
		await lockGroup(tx, input.groupId);
		const target = await ownerAndTarget(tx, input);
		if (target.role === "owner")
			throw new AppError(
				422,
				"OWNER_REQUIRED",
				"Group owner cannot be demoted",
			);
		await updateGroupUserRole(tx, {
			groupId: input.groupId,
			userId: input.targetId,
			role: input.request.role,
		});
		await insertActivity(tx, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: "role_change",
			entityType: "group_user",
			entityId: input.targetId,
			summary: "Group role changed",
			before: { role: target.role },
			after: { ...input.request, name: target.name },
			createdAt: deps.now(),
		});
	});
	deps.events.publishChanged(input.groupId, [
		"users",
		"members",
		"group",
		"activity",
	]);
	return getGroupUsers(deps, input);
}
export async function removeGroupUser(deps: AppDeps, input: UserOperation) {
	await deps.db.transaction(async (tx) => {
		await lockGroup(tx, input.groupId);
		const target = await ownerAndTarget(tx, input);
		if (target.role === "owner")
			throw new AppError(
				422,
				"OWNER_REQUIRED",
				"Group owner cannot be removed",
			);
		await deleteGroupUser(tx, {
			groupId: input.groupId,
			userId: input.targetId,
		});
		await insertActivity(tx, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: "remove",
			entityType: "group_user",
			entityId: input.targetId,
			summary: "User removed",
			after: { name: target.name },
			createdAt: deps.now(),
		});
	});
	deps.events.publishRemoved(input.groupId, input.targetId);
	deps.events.publishChanged(input.groupId, [
		"users",
		"members",
		"group",
		"activity",
	]);
}
export async function leaveGroup(
	deps: AppDeps,
	input: { groupId: string; userId: string },
) {
	await deps.db.transaction(async (tx) => {
		await lockGroup(tx, input.groupId);
		const user = await groupUser(tx, input);
		if (user.role === "owner")
			throw new AppError(422, "OWNER_REQUIRED", "Group owner cannot leave");
		await deleteGroupUser(tx, input);
		await insertActivity(tx, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: "leave",
			entityType: "group_user",
			entityId: input.userId,
			summary: "User left",
			createdAt: deps.now(),
		});
	});
	deps.events.publishRemoved(input.groupId, input.userId);
	deps.events.publishChanged(input.groupId, [
		"users",
		"members",
		"group",
		"activity",
	]);
}
export async function transferOwnership(deps: AppDeps, input: UserOperation) {
	const result = await deps.db.transaction(async (tx) => {
		for (const id of [...new Set([input.userId, input.targetId])].sort())
			await lockAccount(tx, id);
		await lockGroup(tx, input.groupId);
		const target = await ownerAndTarget(tx, input);
		if (input.targetId === input.userId)
			throw new AppError(422, "OWNER_REQUIRED", "Choose another group user");
		const targetApple = await findUserAppleIdentity(tx, input.targetId);
		if (
			targetApple?.providerSecret?.startsWith("REVOKING:") ||
			targetApple?.providerSecret?.startsWith("APPLE_REVOCATION_COMPLETED:")
		) {
			throw new AppError(
				422,
				"OWNER_REQUIRED",
				"Target user is undergoing account deletion",
			);
		}
		await updateGroupUserRole(tx, {
			groupId: input.groupId,
			userId: input.userId,
			role: "editor",
		});
		await updateGroupUserRole(tx, {
			groupId: input.groupId,
			userId: input.targetId,
			role: "owner",
		});
		await insertActivity(tx, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: "transfer_ownership",
			entityType: "group_user",
			entityId: input.targetId,
			summary: "Ownership transferred",
			after: { name: target.name },
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
