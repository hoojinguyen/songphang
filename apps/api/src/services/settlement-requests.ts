import type { z } from "@hono/zod-openapi";
import {
	type CreateSettlementRequest,
	SettlementRequestDto,
	type SettlementRequestsQuery,
	SettlementRequestsResponse,
} from "@songphang/contract";
import {
	type DbExecutor,
	findGroup,
	findMember,
	findPendingSettlement,
	findSettlementRequest,
	findUserById,
	insertSettlementRequest,
	listSettlementRequests,
	lockGroup,
	resolveSettlementRequest,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { getGroupAccess } from "../auth/group-access.js";
import { AppError } from "../errors.js";
import { notify } from "./notify.js";
import { createTransactionIn } from "./transactions.js";

type Access = { role: "owner" | "editor" | "viewer"; memberId: string | null };
type RequestRow = Awaited<ReturnType<typeof insertSettlementRequest>>;
type Actor = { groupId: string; userId: string };
export function mayCreate(access: Access, fromMemberId: string) {
	return access.role !== "viewer" || access.memberId === fromMemberId;
}
export function mayResolve(
	access: Access,
	receiver: { id: string; claimed: boolean },
) {
	return (
		access.role === "owner" ||
		access.memberId === receiver.id ||
		(access.role === "editor" && !receiver.claimed)
	);
}
export function mayCancel(access: Access, row: RequestRow, userId: string) {
	return row.createdBy === userId || row.fromMemberId === access.memberId;
}
async function requestDto(executor: DbExecutor, row: RequestRow) {
	const creator = row.createdBy
		? await findUserById(executor, row.createdBy)
		: null;
	return SettlementRequestDto.parse({
		...row,
		createdBy: creator ? { id: creator.id, name: creator.name } : null,
		createdAt: row.createdAt.toISOString(),
		resolvedAt: row.resolvedAt?.toISOString() ?? null,
	});
}
export async function getSettlementRequests(
	deps: AppDeps,
	groupId: string,
	query: z.infer<typeof SettlementRequestsQuery>,
) {
	const rows = await listSettlementRequests(deps.db, {
		groupId,
		...query,
		limit: query.limit + 1,
	});
	const page = rows.slice(0, query.limit);
	return SettlementRequestsResponse.parse({
		requests: page.map(({ request, creatorName }) => ({
			...request,
			createdBy:
				request.createdBy && creatorName
					? { id: request.createdBy, name: creatorName }
					: null,
			createdAt: request.createdAt.toISOString(),
			resolvedAt: request.resolvedAt?.toISOString() ?? null,
		})),
		nextCursor:
			rows.length > query.limit ? (page.at(-1)?.request.id ?? null) : null,
	});
}
export async function createSettlementRequest(
	executor: DbExecutor,
	input: Actor & { request: CreateSettlementRequest; now: Date },
) {
	await lockGroup(executor, input.groupId);
	const access = await getGroupAccess(executor, {
		...input,
		minimumRole: "viewer",
	});
	if (!mayCreate(access, input.request.fromMemberId))
		throw new AppError(403, "FORBIDDEN", "Insufficient group role");
	for (const id of [input.request.fromMemberId, input.request.toMemberId]) {
		const member = await findMember(executor, input.groupId, id);
		if (member?.kind !== "person")
			throw new AppError(
				400,
				"MEMBER_NOT_IN_GROUP",
				"Member does not belong to group",
			);
	}
	const pending = await findPendingSettlement(executor, {
		groupId: input.groupId,
		...input.request,
	});
	if (pending)
		throw new AppError(
			409,
			"REQUEST_ALREADY_PENDING",
			"A request is already pending",
			{ requestId: pending.id },
		);
	const row = await insertSettlementRequest(executor, {
		groupId: input.groupId,
		...input.request,
		createdBy: input.userId,
		createdAt: input.now,
	});
	const dto = await requestDto(executor, row);
	const group = await findGroup(executor, input.groupId);
	await notify(executor, {
		groupId: input.groupId,
		actorUserId: input.userId,
		kind: "settlement_requested",
		payload: {
			kind: "settlement_requested",
			actorName: dto.createdBy?.name ?? "",
			groupName: group?.name ?? "",
			amount: input.request.amount,
		},
		toMemberIds: [input.request.toMemberId],
		now: input.now,
	});
	return { request: dto };
}
export async function resolveSettlement(
	deps: AppDeps,
	input: Actor & { id: string; action: "confirm" | "reject" | "cancel" },
) {
	const result = await deps.db.transaction(async (executor) => {
		await lockGroup(executor, input.groupId);
		const access = await getGroupAccess(executor, {
			...input,
			minimumRole: "viewer",
		});
		const row = await findSettlementRequest(executor, input.groupId, input.id);
		if (!row) throw new AppError(404, "NOT_FOUND", "Resource not found");
		const receiver = await findMember(executor, input.groupId, row.toMemberId);
		if (!receiver) throw new AppError(404, "NOT_FOUND", "Resource not found");
		const allowed =
			input.action === "cancel"
				? mayCancel(access, row, input.userId)
				: mayResolve(access, receiver);
		if (!allowed)
			throw new AppError(403, "FORBIDDEN", "Insufficient group role");
		if (row.status !== "pending")
			throw new AppError(
				409,
				"REQUEST_NOT_PENDING",
				"Request is no longer pending",
			);
		const now = deps.now();
		const transfer =
			input.action === "confirm"
				? await createTransactionIn(executor, {
						...input,
						now,
						request: {
							type: "transfer",
							fromMemberId: row.fromMemberId,
							toMemberId: row.toMemberId,
							amount: row.amount,
							occurredAt: now.toISOString(),
						},
					})
				: null;
		const updated = await resolveSettlementRequest(executor, {
			...input,
			now,
			status:
				input.action === "confirm"
					? "confirmed"
					: input.action === "reject"
						? "rejected"
						: "cancelled",
			transactionId: transfer?.transaction.id ?? null,
		});
		if (input.action === "confirm" || input.action === "reject") {
			const [group, actor] = await Promise.all([
				findGroup(executor, input.groupId),
				findUserById(executor, input.userId),
			]);
			const kind =
				input.action === "confirm"
					? "settlement_confirmed"
					: "settlement_rejected";
			await notify(executor, {
				groupId: input.groupId,
				actorUserId: input.userId,
				kind,
				payload: {
					kind,
					actorName: actor?.name ?? "",
					groupName: group?.name ?? "",
					amount: row.amount,
				},
				toMemberIds: [row.fromMemberId],
				now,
			});
		}
		return {
			request: await requestDto(executor, updated),
			...(transfer ? { transaction: transfer.transaction } : {}),
		};
	});
	deps.events.publishChanged(
		input.groupId,
		input.action === "confirm"
			? ["settlementRequests", "transactions", "balances", "activity"]
			: ["settlementRequests"],
	);
	return result;
}
