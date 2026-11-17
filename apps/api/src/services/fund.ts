import { z } from "@hono/zod-openapi";
import {
	type CreateFundRequest,
	MemberResponse,
	type UpdateFundRequest,
} from "@songphang/contract";
import {
	type DbExecutor,
	deleteMember,
	findFund,
	findMember,
	hasMemberSettlementRequests,
	hasMemberTransactions,
	insertActivity,
	insertMember,
	listGroupMembers,
	listMemberBalances,
	lockGroup,
	updateMember,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { getGroupAccess } from "../auth/group-access.js";
import { AppError } from "../errors.js";

const DEFAULT_FUND_NAME = "Quỹ chung";

async function validateHolder(
	executor: DbExecutor,
	groupId: string,
	holderMemberId: string | null | undefined,
): Promise<string | null> {
	if (holderMemberId === undefined || holderMemberId === null) return null;
	if (!z.uuid().safeParse(holderMemberId).success)
		throw new AppError(
			400,
			"MEMBER_NOT_IN_GROUP",
			"Member does not belong to group",
		);
	const person = await findMember(executor, groupId, holderMemberId);
	if (person === null || person.kind !== "person")
		throw new AppError(
			400,
			"MEMBER_NOT_IN_GROUP",
			"Member does not belong to group",
		);
	return person.id;
}

export async function createFund(
	executor: DbExecutor,
	input: {
		groupId: string;
		userId: string;
		request: CreateFundRequest;
		now: Date;
	},
) {
	await lockGroup(executor, input.groupId);
	await getGroupAccess(executor, { ...input, minimumRole: "editor" });
	if ((await findFund(executor, input.groupId)) !== null)
		throw new AppError(409, "FUND_EXISTS", "Group already has a fund");
	const members = await listGroupMembers(executor, input.groupId);
	if (members.length >= 100)
		throw new AppError(
			400,
			"VALIDATION_FAILED",
			"Group has reached its member limit",
			{ members: ["At most 100 members"] },
		);
	const holderId = await validateHolder(
		executor,
		input.groupId,
		input.request.holderMemberId,
	);
	const position = (members.at(-1)?.position ?? -1) + 1;
	const fund = await insertMember(executor, {
		groupId: input.groupId,
		kind: "fund",
		fundHolderMemberId: holderId,
		name: input.request.name ?? DEFAULT_FUND_NAME,
		position,
		shape: "fund",
		color: "sun",
		createdAt: input.now,
		updatedAt: input.now,
	});
	await insertActivity(executor, {
		groupId: input.groupId,
		actorUserId: input.userId,
		action: "create",
		entityType: "member",
		entityId: fund.id,
		summary: fund.name,
		after: { kind: "fund", name: fund.name, holderMemberId: holderId },
		createdAt: input.now,
	});
	return MemberResponse.parse({ member: { ...fund, isMe: false } });
}

export async function updateFund(
	deps: AppDeps,
	input: {
		groupId: string;
		userId: string;
		request: UpdateFundRequest;
	},
) {
	const result = await deps.db.transaction(async (executor) => {
		await lockGroup(executor, input.groupId);
		await getGroupAccess(executor, { ...input, minimumRole: "editor" });
		const before = await findFund(executor, input.groupId);
		if (before === null)
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		const holder =
			input.request.holderMemberId === undefined
				? undefined
				: await validateHolder(
						executor,
						input.groupId,
						input.request.holderMemberId,
					);
		if (input.request.active === false) {
			const balances = await listMemberBalances(executor, input.groupId);
			const fundBalance =
				balances.find((row) => row.memberId === before.id)?.balance ?? 0;
			if (fundBalance !== 0)
				throw new AppError(
					422,
					"FUND_NOT_EMPTY",
					"Fund cash must be zero before deactivating",
				);
		}
		await updateMember(executor, {
			groupId: input.groupId,
			memberId: before.id,
			changes: {
				...(input.request.name === undefined
					? {}
					: { name: input.request.name }),
				...(holder === undefined ? {} : { fundHolderMemberId: holder }),
				...(input.request.active === undefined
					? {}
					: { active: input.request.active }),
				updatedAt: deps.now(),
			},
		});
		const after = await findFund(executor, input.groupId);
		if (after === null) throw new Error("Fund missing after update");
		await insertActivity(executor, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: "update",
			entityType: "member",
			entityId: after.id,
			summary: after.name,
			before: {
				name: before.name,
				active: before.active,
				holderMemberId: before.fundHolderMemberId,
			},
			after: {
				name: after.name,
				active: after.active,
				holderMemberId: after.fundHolderMemberId,
			},
			createdAt: deps.now(),
		});
		return MemberResponse.parse({ member: { ...after, isMe: false } });
	});
	deps.events.publishChanged(input.groupId, [
		"members",
		"balances",
		"activity",
	]);
	return result;
}

export async function deleteFund(
	deps: AppDeps,
	input: { groupId: string; userId: string },
) {
	await deps.db.transaction(async (executor) => {
		await lockGroup(executor, input.groupId);
		await getGroupAccess(executor, { ...input, minimumRole: "editor" });
		const fund = await findFund(executor, input.groupId);
		if (fund === null)
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		if (
			(await hasMemberTransactions(executor, input.groupId, fund.id)) ||
			(await hasMemberSettlementRequests(executor, input.groupId, fund.id))
		)
			throw new AppError(
				422,
				"MEMBER_HAS_TRANSACTIONS",
				"Member has transactions",
			);
		await deleteMember(executor, input.groupId, fund.id);
		await insertActivity(executor, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: "delete",
			entityType: "member",
			entityId: fund.id,
			summary: fund.name,
			before: fund,
			createdAt: deps.now(),
		});
	});
	deps.events.publishChanged(input.groupId, [
		"group",
		"members",
		"balances",
		"activity",
	]);
}
