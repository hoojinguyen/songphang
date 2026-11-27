import {
	JOB_NAMES,
	ProcessRecurringPayload,
	RecurringDuePayload,
	RecurringPayerTemplateEntry,
	RecurringPostedPayload,
	SplitInput,
} from "@songphang/contract";
import {
	approvalStatusFor,
	computeNextDueDate,
	computeShares,
	foldVietnamese,
	hourInVietnam,
	type RecurringSchedule,
	todayInVietnam,
} from "@songphang/core";
import {
	type DbExecutor,
	findGroup,
	findGroupOwner,
	findRecurringExpense,
	insertActivity,
	insertNotificationRows,
	insertTransaction,
	insertTransactionPayers,
	insertTransactionShares,
	listDueRecurringExpenses,
	listGroupMembers,
	listGroupUsers,
	lockGroup,
	type RecurringExpenseRow,
	resolveNotificationRecipients,
	updateRecurringExpense,
} from "@songphang/db";
import type { PgBoss } from "pg-boss";
import { z } from "zod";
import { notifyGroup } from "../notify.js";
import { registerJob, type WorkerDeps } from "../queue.js";
import { runSendNotificationMail } from "./send-notification-mail.js";
import { runSendPush } from "./send-push.js";

function scheduleFromRow(row: RecurringExpenseRow): RecurringSchedule {
	if (row.frequency === "weekly" && row.dayOfWeek !== null) {
		return { frequency: "weekly", dayOfWeek: row.dayOfWeek };
	}
	if (
		(row.frequency === "monthly" || row.frequency === "quarterly") &&
		row.dayOfMonth !== null
	) {
		return { frequency: row.frequency, dayOfMonth: row.dayOfMonth };
	}
	if (
		row.frequency === "yearly" &&
		row.monthOfYear !== null &&
		row.dayOfMonth !== null
	) {
		return {
			frequency: "yearly",
			monthOfYear: row.monthOfYear,
			dayOfMonth: row.dayOfMonth,
		};
	}
	throw new Error(`Invalid recurring schedule on row ${row.id}`);
}

function splitMemberIds(split: SplitInput): string[] {
	if (split.method === "equal" || split.method === "exact") {
		return [...split.members];
	}
	if (split.method === "items") {
		return [...new Set(split.items.flatMap((item) => item.memberIds))];
	}
	return split.entries.map((entry) => entry.memberId);
}

async function pauseInvalidRecurring(
	executor: DbExecutor,
	input: {
		row: RecurringExpenseRow;
		reason: "member_invalid" | "split_invalid";
		now: Date;
	},
) {
	await updateRecurringExpense(executor, input.row.groupId, input.row.id, {
		active: false,
		pauseReason: input.reason,
		pendingDueDate: null,
		updatedAt: input.now,
	});
	await insertActivity(executor, {
		groupId: input.row.groupId,
		actorUserId: input.row.updatedBy ?? input.row.createdBy,
		action: "recurring.paused",
		entityType: "recurring_expense",
		entityId: input.row.id,
		summary: input.row.description,
		after: { pauseReason: input.reason },
		createdAt: input.now,
	});
	await notifyGroup(executor, input.row.groupId, [
		"recurringExpenses",
		"activity",
	]);
}

async function enqueueNotificationDeliveries(
	executor: DbExecutor,
	deps: WorkerDeps,
	rows: Array<{ id: string }>,
	collectedIds: string[],
	options: { sendMail: boolean },
) {
	for (const item of rows) {
		collectedIds.push(item.id);
		if (!deps.enqueue) continue;
		if (options.sendMail) {
			await deps.enqueue(
				executor,
				JOB_NAMES.sendNotificationMail,
				{ notificationId: item.id },
				{ singletonKey: item.id },
			);
		}
		if (deps.config.pushProvider) {
			await deps.enqueue(
				executor,
				JOB_NAMES.sendPush,
				{ notificationId: item.id },
				{ singletonKey: item.id },
			);
		}
	}
}

async function processFixedRecurring(
	executor: DbExecutor,
	deps: WorkerDeps,
	input: {
		row: RecurringExpenseRow;
		groupName: string;
		currency: string;
		approvalThreshold: number | null;
		members: Awaited<ReturnType<typeof listGroupMembers>>;
		payers: Array<z.infer<typeof RecurringPayerTemplateEntry>>;
		split: SplitInput;
		dueDate: string;
		advancedNextDueDate: string;
		now: Date;
		notificationIds: string[];
	},
): Promise<boolean> {
	const amount = input.row.amount;
	if (
		amount === null ||
		input.payers.some((payer) => payer.amount === undefined) ||
		input.payers.reduce((sum, p) => sum + (p.amount ?? 0), 0) !== amount
	) {
		await pauseInvalidRecurring(executor, {
			row: input.row,
			reason: "split_invalid",
			now: input.now,
		});
		return false;
	}

	const splitResult = computeShares(
		amount,
		input.split,
		input.members.map((m) => m.id),
	);
	if (!splitResult.ok) {
		await pauseInvalidRecurring(executor, {
			row: input.row,
			reason: "split_invalid",
			now: input.now,
		});
		return false;
	}

	const owner = await findGroupOwner(executor, input.row.groupId);
	const actorUserId =
		input.row.updatedBy ?? input.row.createdBy ?? owner?.userId ?? null;
	const actorIsOwner = owner !== null && owner.userId === actorUserId;
	const approvalStatus = approvalStatusFor({
		type: "expense",
		amount,
		threshold: input.approvalThreshold,
		actorIsOwner,
	});

	const txRow = await insertTransaction(executor, {
		groupId: input.row.groupId,
		type: "expense",
		description: input.row.description,
		descriptionSearch: foldVietnamese(input.row.description),
		amount,
		currency: input.currency,
		occurredAt: input.now,
		category: input.row.category,
		categoryId: input.row.categoryId,
		splitMethod: input.split.method,
		splitInput: input.split,
		approvalStatus,
		paymentChannel: null,
		paymentNote: null,
		recurringExpenseId: input.row.id,
		createdBy: actorUserId,
		updatedBy: actorUserId,
		createdAt: input.now,
		updatedAt: input.now,
	});
	const resolvedPayers = input.payers.map((payer) => ({
		memberId: payer.memberId,
		amount: payer.amount ?? 0,
	}));
	await insertTransactionPayers(
		executor,
		resolvedPayers.map((payer) => ({ ...payer, transactionId: txRow.id })),
	);
	await insertTransactionShares(
		executor,
		splitResult.shares.map((share) => ({
			...share,
			transactionId: txRow.id,
		})),
	);
	await updateRecurringExpense(executor, input.row.groupId, input.row.id, {
		lastProcessedDueDate: input.dueDate,
		nextDueDate: input.advancedNextDueDate,
		lastPostedAt: input.now,
		lastTransactionId: txRow.id,
		pauseReason: null,
		updatedAt: input.now,
	});
	await insertActivity(executor, {
		groupId: input.row.groupId,
		actorUserId,
		action: "recurring_post",
		entityType: "transaction",
		entityId: txRow.id,
		summary: input.row.description,
		after: {
			recurringExpenseId: input.row.id,
			amount,
			dueDate: input.dueDate,
			shares: splitResult.shares,
		},
		createdAt: input.now,
	});

	const shareByMember = new Map<string, number>();
	for (const payer of resolvedPayers) shareByMember.set(payer.memberId, 0);
	for (const share of splitResult.shares) {
		shareByMember.set(share.memberId, share.amount);
	}
	for (const [memberId, share] of shareByMember) {
		const recipients = await resolveNotificationRecipients(executor, {
			groupId: input.row.groupId,
			actorUserId: null,
			memberIds: [memberId],
		});
		if (recipients.length === 0) continue;
		const payload = RecurringPostedPayload.parse({
			kind: "recurring_posted",
			groupName: input.groupName,
			transactionId: txRow.id,
			description: input.row.description,
			amount,
			share,
		});
		const inserted = await insertNotificationRows(
			executor,
			recipients.map((userId) => ({
				userId,
				groupId: input.row.groupId,
				kind: "recurring_posted",
				payload,
				createdAt: input.now,
			})),
		);
		await enqueueNotificationDeliveries(
			executor,
			deps,
			inserted,
			input.notificationIds,
			{ sendMail: false },
		);
	}

	await notifyGroup(executor, input.row.groupId, [
		"transactions",
		"balances",
		"activity",
		"recurringExpenses",
	]);
	return true;
}

async function processVariableRecurring(
	executor: DbExecutor,
	deps: WorkerDeps,
	input: {
		row: RecurringExpenseRow;
		groupName: string;
		payers: Array<z.infer<typeof RecurringPayerTemplateEntry>>;
		dueDate: string;
		advancedNextDueDate: string;
		now: Date;
		notificationIds: string[];
	},
): Promise<boolean> {
	await updateRecurringExpense(executor, input.row.groupId, input.row.id, {
		pendingDueDate: input.dueDate,
		lastProcessedDueDate: input.dueDate,
		nextDueDate: input.advancedNextDueDate,
		pauseReason: null,
		updatedAt: input.now,
	});

	const groupUsersList = await listGroupUsers(executor, input.row.groupId);
	const payerMemberId = input.payers[0]?.memberId;
	const payerUser = groupUsersList.find((gu) => gu.memberId === payerMemberId);
	const targetUserIds: string[] = [];
	if (
		payerUser &&
		(payerUser.role === "owner" || payerUser.role === "editor")
	) {
		targetUserIds.push(payerUser.userId);
	} else {
		const creatorId = input.row.updatedBy ?? input.row.createdBy;
		const creatorUser = creatorId
			? groupUsersList.find(
					(gu) =>
						gu.userId === creatorId &&
						(gu.role === "owner" || gu.role === "editor"),
				)
			: undefined;
		if (creatorUser) targetUserIds.push(creatorUser.userId);
		const ownerUser = groupUsersList.find((gu) => gu.role === "owner");
		if (ownerUser && !targetUserIds.includes(ownerUser.userId)) {
			targetUserIds.push(ownerUser.userId);
		}
	}

	const recipients = await resolveNotificationRecipients(executor, {
		groupId: input.row.groupId,
		actorUserId: null,
		userIds: targetUserIds,
	});
	if (recipients.length > 0) {
		const payload = RecurringDuePayload.parse({
			kind: "recurring_due",
			groupName: input.groupName,
			recurringExpenseId: input.row.id,
			description: input.row.description,
			dueDate: input.dueDate,
		});
		const inserted = await insertNotificationRows(
			executor,
			recipients.map((userId) => ({
				userId,
				groupId: input.row.groupId,
				kind: "recurring_due",
				payload,
				createdAt: input.now,
			})),
		);
		await enqueueNotificationDeliveries(
			executor,
			deps,
			inserted,
			input.notificationIds,
			{ sendMail: true },
		);
	}

	await notifyGroup(executor, input.row.groupId, ["recurringExpenses"]);
	return true;
}

export async function runProcessRecurring(deps: WorkerDeps): Promise<number> {
	const now = deps.now();
	const todayVN = todayInVietnam(now);
	const dueRows = await listDueRecurringExpenses(deps.db, todayVN);
	const mailNotificationIds: string[] = [];
	const pushNotificationIds: string[] = [];
	let processedCount = 0;

	for (const candidate of dueRows) {
		const outcome = await deps.db.transaction(async (executor) => {
			const locked = await lockGroup(executor, candidate.groupId);
			const row = await findRecurringExpense(
				executor,
				candidate.groupId,
				candidate.id,
			);
			if (
				locked === null ||
				locked.archivedAt !== null ||
				row === null ||
				!row.active ||
				row.nextDueDate > todayVN ||
				row.lastProcessedDueDate === row.nextDueDate
			) {
				return null;
			}
			const group = await findGroup(executor, candidate.groupId);
			if (group === null) return null;

			const members = await listGroupMembers(executor, candidate.groupId);
			const memberById = new Map(members.map((m) => [m.id, m]));
			const payers = z
				.array(RecurringPayerTemplateEntry)
				.parse(row.payersTemplate);
			const split = SplitInput.parse(row.splitTemplate);
			const splitIds = splitMemberIds(split);
			const allReferenced = [...payers.map((p) => p.memberId), ...splitIds];
			const hasInvalidMember =
				allReferenced.some((id) => !memberById.get(id)?.active) ||
				splitIds.some((id) => memberById.get(id)?.kind === "fund");

			if (hasInvalidMember) {
				await pauseInvalidRecurring(executor, {
					row,
					reason: "member_invalid",
					now,
				});
				return null;
			}

			const dueDate = row.nextDueDate;
			const advancedNextDueDate = computeNextDueDate(
				scheduleFromRow(row),
				todayVN,
				false,
			);
			const createdIds: string[] = [];

			if (row.mode === "fixed") {
				const posted = await processFixedRecurring(executor, deps, {
					row,
					groupName: group.name,
					currency: group.currency,
					approvalThreshold: group.approvalThreshold,
					members,
					payers,
					split,
					dueDate,
					advancedNextDueDate,
					now,
					notificationIds: createdIds,
				});
				return posted ? { kind: "fixed" as const, createdIds } : null;
			}

			const prompted = await processVariableRecurring(executor, deps, {
				row,
				groupName: group.name,
				payers,
				dueDate,
				advancedNextDueDate,
				now,
				notificationIds: createdIds,
			});
			return prompted ? { kind: "variable" as const, createdIds } : null;
		});

		if (outcome !== null) {
			processedCount += 1;
			if (outcome.kind === "variable") {
				mailNotificationIds.push(...outcome.createdIds);
			}
			pushNotificationIds.push(...outcome.createdIds);
		}
	}

	if (!deps.enqueue) {
		for (const id of mailNotificationIds) {
			await runSendNotificationMail(deps, id);
		}
		if (deps.config.pushProvider) {
			for (const id of pushNotificationIds) {
				await runSendPush(deps, id);
			}
		}
	}
	return processedCount;
}

export async function registerProcessRecurringJob(
	boss: PgBoss,
	deps: WorkerDeps,
): Promise<void> {
	await registerJob(
		boss,
		JOB_NAMES.processRecurring,
		ProcessRecurringPayload,
		async (_data, workerDeps) => {
			if (hourInVietnam(workerDeps.now()) < 8) return;
			await runProcessRecurring(workerDeps);
		},
		deps,
	);
	await boss.schedule(
		JOB_NAMES.processRecurring,
		"0 * * * *",
		{},
		{ tz: "Asia/Ho_Chi_Minh" },
	);
}
