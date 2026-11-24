import {
	type ReminderPairDto,
	type SendReminderRequest,
	SendReminderResponse,
	type SkippedReminderDto,
} from "@songphang/contract";
import {
	type DbExecutor,
	findGroup,
	findLatestDebtReminder,
	findUserById,
	insertDebtReminder,
	listGroupMembers,
	lockGroup,
	suggestGroupTransfers,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { getGroupAccess } from "../auth/group-access.js";
import { AppError } from "../errors.js";
import type { EnqueueFn } from "../queue.js";
import { assertGroupRowNotArchived } from "./group-guards.js";
import { notify } from "./notify.js";

const MANUAL_COOLDOWN_MS = 24 * 60 * 60 * 1000;

async function recordPairReminder(
	executor: DbExecutor,
	input: {
		groupId: string;
		groupName: string;
		actorUserId: string;
		actorName: string;
		fromMemberId: string;
		toMemberId: string;
		toName: string;
		amount: number;
		now: Date;
		enqueue: EnqueueFn;
		pushEnabled?: boolean;
	},
): Promise<void> {
	await insertDebtReminder(executor, {
		groupId: input.groupId,
		fromMemberId: input.fromMemberId,
		toMemberId: input.toMemberId,
		amount: input.amount,
		sentBy: input.actorUserId,
		createdAt: input.now,
	});
	await notify(executor, {
		groupId: input.groupId,
		actorUserId: input.actorUserId,
		kind: "debt_reminder",
		payload: {
			kind: "debt_reminder",
			actorName: input.actorName,
			groupName: input.groupName,
			toName: input.toName,
			amount: input.amount,
		},
		toMemberIds: [input.fromMemberId],
		now: input.now,
		enqueue: input.enqueue,
		...(input.pushEnabled === undefined
			? {}
			: { pushEnabled: input.pushEnabled }),
	});
}

async function checkPairCooldown(
	executor: DbExecutor,
	groupId: string,
	fromMemberId: string,
	toMemberId: string,
	now: Date,
): Promise<Date | null> {
	const latest = await findLatestDebtReminder(executor, {
		groupId,
		fromMemberId,
		toMemberId,
	});
	if (latest === null) return null;
	const nextAt = new Date(latest.createdAt.getTime() + MANUAL_COOLDOWN_MS);
	return nextAt.getTime() > now.getTime() ? nextAt : null;
}

export async function sendReminders(
	deps: AppDeps,
	input: { groupId: string; userId: string; request: SendReminderRequest },
): Promise<SendReminderResponse> {
	const now = deps.now();
	const response = await deps.db.transaction(async (executor) => {
		const lockedGroup = await lockGroup(executor, input.groupId);
		const access = await getGroupAccess(executor, {
			groupId: input.groupId,
			userId: input.userId,
			minimumRole: "viewer",
		});
		assertGroupRowNotArchived(lockedGroup);
		const group = await findGroup(executor, input.groupId);
		if (group === null)
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		const [{ transfers }, members, actor] = await Promise.all([
			suggestGroupTransfers(executor, {
				groupId: input.groupId,
				minimizeDebts: group.minimizeDebts,
			}),
			listGroupMembers(executor, input.groupId),
			findUserById(executor, input.userId),
		]);
		const memberById = new Map(members.map((m) => [m.id, m]));
		const mayRemind = (toMemberId: string) =>
			access.role !== "viewer" || access.memberId === toMemberId;
		const actorName = actor?.name ?? "";

		if ("fromMemberId" in input.request) {
			const { fromMemberId, toMemberId } = input.request;
			const transfer = transfers.find(
				(t) => t.fromMemberId === fromMemberId && t.toMemberId === toMemberId,
			);
			if (!transfer)
				throw new AppError(
					400,
					"VALIDATION_FAILED",
					"Pair is not a suggested transfer",
				);
			if (!mayRemind(transfer.toMemberId))
				throw new AppError(403, "FORBIDDEN", "Insufficient group role");
			const fromMember = memberById.get(transfer.fromMemberId);
			const toMember = memberById.get(transfer.toMemberId);
			if (!fromMember || !toMember)
				throw new AppError(400, "MEMBER_NOT_IN_GROUP", "Member not found");
			if (!fromMember.claimed)
				throw new AppError(
					422,
					"MEMBER_NOT_LINKED",
					"Member is not linked to a user",
				);
			const blockedUntil = await checkPairCooldown(
				executor,
				input.groupId,
				transfer.fromMemberId,
				transfer.toMemberId,
				now,
			);
			if (blockedUntil !== null) {
				throw new AppError(
					429,
					"REMINDER_TOO_SOON",
					"Reminder sent too recently",
					{ nextAt: blockedUntil.toISOString() },
				);
			}
			await recordPairReminder(executor, {
				groupId: input.groupId,
				groupName: group.name,
				actorUserId: input.userId,
				actorName,
				fromMemberId: transfer.fromMemberId,
				toMemberId: transfer.toMemberId,
				toName: toMember.name,
				amount: transfer.amount,
				now,
				enqueue: deps.enqueue,
				pushEnabled: Boolean(deps.config.pushProvider),
			});
			return SendReminderResponse.parse({
				reminded: [
					{
						fromMemberId: transfer.fromMemberId,
						toMemberId: transfer.toMemberId,
					},
				],
				skipped: [],
			});
		}

		const reminded: ReminderPairDto[] = [];
		const skipped: SkippedReminderDto[] = [];
		for (const transfer of transfers) {
			if (!mayRemind(transfer.toMemberId)) continue;
			const fromMember = memberById.get(transfer.fromMemberId);
			const toMember = memberById.get(transfer.toMemberId);
			if (!fromMember || !toMember) continue;
			if (!fromMember.claimed) {
				skipped.push({
					fromMemberId: transfer.fromMemberId,
					toMemberId: transfer.toMemberId,
					reason: "MEMBER_NOT_LINKED",
				});
				continue;
			}
			const blockedUntil = await checkPairCooldown(
				executor,
				input.groupId,
				transfer.fromMemberId,
				transfer.toMemberId,
				now,
			);
			if (blockedUntil !== null) {
				skipped.push({
					fromMemberId: transfer.fromMemberId,
					toMemberId: transfer.toMemberId,
					reason: "REMINDER_TOO_SOON",
				});
				continue;
			}
			await recordPairReminder(executor, {
				groupId: input.groupId,
				groupName: group.name,
				actorUserId: input.userId,
				actorName,
				fromMemberId: transfer.fromMemberId,
				toMemberId: transfer.toMemberId,
				toName: toMember.name,
				amount: transfer.amount,
				now,
				enqueue: deps.enqueue,
				pushEnabled: Boolean(deps.config.pushProvider),
			});
			reminded.push({
				fromMemberId: transfer.fromMemberId,
				toMemberId: transfer.toMemberId,
			});
		}
		return SendReminderResponse.parse({ reminded, skipped });
	});
	if (response.reminded.length > 0) {
		deps.events.publishChanged(input.groupId, ["balances"]);
	}
	return response;
}
