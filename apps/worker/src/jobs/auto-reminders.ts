import {
	AutoRemindersPayload,
	JOB_NAMES,
	NotificationPayload,
} from "@songphang/contract";
import {
	findLatestDebtReminder,
	insertDebtReminder,
	insertNotificationRows,
	listGroupMembers,
	listGroupsWithReminderInterval,
	lockGroup,
	resolveNotificationRecipients,
	suggestGroupTransfers,
} from "@songphang/db";
import type { PgBoss } from "pg-boss";
import { notifyGroup } from "../notify.js";
import { registerJob, type WorkerDeps } from "../queue.js";
import { runSendNotificationMail } from "./send-notification-mail.js";

const DAY_MS = 24 * 60 * 60 * 1000;

export async function runAutoReminders(deps: WorkerDeps): Promise<number> {
	const now = deps.now();
	const groups = await listGroupsWithReminderInterval(deps.db);
	const notificationIds: string[] = [];
	let remindedCount = 0;

	for (const group of groups) {
		const intervalDays = group.reminderIntervalDays;
		if (intervalDays === null) continue;
		const intervalMs = intervalDays * DAY_MS;

		const createdIds = await deps.db.transaction(async (executor) => {
			await lockGroup(executor, group.id);
			const [{ transfers }, members] = await Promise.all([
				suggestGroupTransfers(executor, {
					groupId: group.id,
					minimizeDebts: group.minimizeDebts,
				}),
				listGroupMembers(executor, group.id),
			]);
			const memberById = new Map(members.map((m) => [m.id, m]));
			const ids: string[] = [];

			for (const transfer of transfers) {
				const fromMember = memberById.get(transfer.fromMemberId);
				const toMember = memberById.get(transfer.toMemberId);
				if (!fromMember?.claimed || !toMember) continue;

				const latest = await findLatestDebtReminder(executor, {
					groupId: group.id,
					fromMemberId: transfer.fromMemberId,
					toMemberId: transfer.toMemberId,
				});
				if (latest && now.getTime() - latest.createdAt.getTime() < intervalMs) {
					continue;
				}
				await insertDebtReminder(executor, {
					groupId: group.id,
					fromMemberId: transfer.fromMemberId,
					toMemberId: transfer.toMemberId,
					amount: transfer.amount,
					sentBy: null,
					createdAt: now,
				});
				remindedCount += 1;

				const recipients = await resolveNotificationRecipients(executor, {
					groupId: group.id,
					actorUserId: null,
					memberIds: [transfer.fromMemberId],
				});
				if (recipients.length === 0) continue;
				const payload = NotificationPayload.parse({
					kind: "debt_reminder",
					actorName: "",
					groupName: group.name,
					toName: toMember.name,
					amount: transfer.amount,
				});
				const rows = await insertNotificationRows(
					executor,
					recipients.map((userId) => ({
						userId,
						groupId: group.id,
						kind: "debt_reminder",
						payload,
						createdAt: now,
					})),
				);
				for (const row of rows) {
					ids.push(row.id);
					if (deps.enqueue) {
						await deps.enqueue(
							executor,
							JOB_NAMES.sendNotificationMail,
							{ notificationId: row.id },
							{ singletonKey: row.id },
						);
					}
				}
			}
			if (ids.length > 0) {
				await notifyGroup(executor, group.id, ["balances"]);
			}
			return ids;
		});
		notificationIds.push(...createdIds);
	}

	if (!deps.enqueue) {
		for (const id of notificationIds) {
			await runSendNotificationMail(deps, id);
		}
	}
	return remindedCount;
}

export async function registerAutoRemindersJob(
	boss: PgBoss,
	deps: WorkerDeps,
): Promise<void> {
	await registerJob(
		boss,
		JOB_NAMES.autoReminders,
		AutoRemindersPayload,
		async (_data, workerDeps) => {
			await runAutoReminders(workerDeps);
		},
		deps,
	);
	await boss.schedule(
		JOB_NAMES.autoReminders,
		"0 9 * * *",
		{},
		{ tz: "Asia/Ho_Chi_Minh" },
	);
}
