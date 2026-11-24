import { z } from "@hono/zod-openapi";
import {
	type CreateMemberRequest,
	MemberColorCode,
	MemberResponse,
	MemberShapeCode,
	MembersResponse,
	nextMemberAppearance,
	type UpdateMemberRequest,
} from "@songphang/contract";
import {
	type DbExecutor,
	deleteMember,
	findMember,
	hasMemberSettlementRequests,
	hasMemberTransactions,
	insertActivity,
	insertMember,
	listGroupMembers,
	listPaymentMethodsByGroup,
	lockGroup,
	updateMember,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { getGroupAccess } from "../auth/group-access.js";
import { AppError } from "../errors.js";
import { assertGroupRowNotArchived } from "./group-guards.js";
import { paymentMethodDto } from "./payment-methods.js";

type MemberOperation = {
	groupId: string;
	userId: string;
	myMemberId: string | null;
};
export async function listMembers(deps: AppDeps, input: MemberOperation) {
	const members = await listGroupMembers(deps.db, input.groupId);
	const payments = await listPaymentMethodsByGroup(deps.db, input.groupId);
	return MembersResponse.parse({
		members: members.map((member) => ({
			...member,
			isMe: member.id === input.myMemberId,
			paymentMethods: payments.get(member.id)?.map(paymentMethodDto) ?? [],
		})),
	});
}
async function getMember(
	executor: DbExecutor,
	groupId: string,
	memberId: string,
) {
	if (!z.uuid().safeParse(memberId).success)
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	const member = await findMember(executor, groupId, memberId);
	if (member === null || member.kind !== "person")
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	return member;
}
export async function createMember(
	executor: DbExecutor,
	input: MemberOperation & { request: CreateMemberRequest; now: Date },
) {
	const group = await lockGroup(executor, input.groupId);
	await getGroupAccess(executor, { ...input, minimumRole: "editor" });
	assertGroupRowNotArchived(group);
	return addGroupMember(executor, input);
}
export async function addGroupMember(
	executor: DbExecutor,
	input: MemberOperation & { request: CreateMemberRequest; now: Date },
) {
	const members = await listGroupMembers(executor, input.groupId);
	if (members.length >= 100)
		throw new AppError(
			400,
			"VALIDATION_FAILED",
			"Group has reached its member limit",
			{ members: ["At most 100 members"] },
		);
	const position = (members.at(-1)?.position ?? -1) + 1;
	const appearance = nextMemberAppearance(
		members
			.filter((member) => member.kind === "person")
			.map((member) => ({
				shape: MemberShapeCode.parse(member.shape),
				color: MemberColorCode.parse(member.color),
			})),
		position,
	);
	const member = await insertMember(executor, {
		groupId: input.groupId,
		name: input.request.name,
		position,
		...appearance,
		createdAt: input.now,
		updatedAt: input.now,
	});
	await insertActivity(executor, {
		groupId: input.groupId,
		actorUserId: input.userId,
		action: "create",
		entityType: "member",
		entityId: member.id,
		summary: member.name,
		createdAt: input.now,
	});
	return MemberResponse.parse({ member: { ...member, isMe: false } });
}
export async function editMember(
	deps: AppDeps,
	input: MemberOperation & { memberId: string; request: UpdateMemberRequest },
) {
	const result = await deps.db.transaction(async (transaction) => {
		const group = await lockGroup(transaction, input.groupId);
		await getGroupAccess(transaction, { ...input, minimumRole: "editor" });
		assertGroupRowNotArchived(group);
		const before = await getMember(transaction, input.groupId, input.memberId);
		const { name, active, defaultWeight } = input.request;
		await updateMember(transaction, {
			groupId: input.groupId,
			memberId: input.memberId,
			changes: {
				...(name === undefined ? {} : { name }),
				...(active === undefined ? {} : { active }),
				...(defaultWeight === undefined ? {} : { defaultWeight }),
				updatedAt: deps.now(),
			},
		});
		const member = await getMember(transaction, input.groupId, input.memberId);
		const fields = Object.keys(input.request);
		await insertActivity(transaction, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: "update",
			entityType: "member",
			entityId: member.id,
			summary: member.name,
			before: Object.fromEntries(
				Object.entries(before).filter(([key]) => fields.includes(key)),
			),
			after: Object.fromEntries(
				Object.entries(member).filter(([key]) => fields.includes(key)),
			),
			createdAt: deps.now(),
		});
		return MemberResponse.parse({
			member: {
				...member,
				isMe: member.id === input.myMemberId,
				paymentMethods:
					(await listPaymentMethodsByGroup(transaction, input.groupId))
						.get(member.id)
						?.map(paymentMethodDto) ?? [],
			},
		});
	});
	deps.events.publishChanged(input.groupId, [
		"members",
		"balances",
		"activity",
	]);
	return result;
}
export async function removeMember(
	deps: AppDeps,
	input: MemberOperation & { memberId: string },
) {
	await deps.db.transaction(async (transaction) => {
		const group = await lockGroup(transaction, input.groupId);
		await getGroupAccess(transaction, { ...input, minimumRole: "editor" });
		assertGroupRowNotArchived(group);
		const member = await getMember(transaction, input.groupId, input.memberId);
		if (
			(await hasMemberTransactions(transaction, input.groupId, member.id)) ||
			(await hasMemberSettlementRequests(transaction, input.groupId, member.id))
		)
			throw new AppError(
				422,
				"MEMBER_HAS_TRANSACTIONS",
				"Member has transactions",
			);
		await deleteMember(transaction, input.groupId, member.id);
		await insertActivity(transaction, {
			groupId: input.groupId,
			actorUserId: input.userId,
			action: "delete",
			entityType: "member",
			entityId: member.id,
			summary: member.name,
			before: member,
			createdAt: deps.now(),
		});
	});
	deps.events.publishChanged(input.groupId, [
		"group",
		"users",
		"members",
		"balances",
		"activity",
	]);
}
