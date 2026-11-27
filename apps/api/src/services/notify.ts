import {
	JOB_NAMES,
	NotificationPayload,
	type TransactionWarning,
} from "@songphang/contract";
import {
	type DbExecutor,
	findGroupOwnerUserId,
	insertNotificationRows,
	resolveNotificationRecipients,
} from "@songphang/db";
import type { EnqueueFn } from "../queue.js";

const IMMEDIATE_KINDS = new Set<NotificationPayload["kind"]>([
	"dispute_opened",
	"dispute_resolved",
	"settlement_requested",
	"settlement_confirmed",
	"settlement_rejected",
	"debt_reminder",
	"approval_requested",
	"approval_decided",
]);

const PUSH_KINDS = new Set<NotificationPayload["kind"]>([
	...IMMEDIATE_KINDS,
	"expense_added",
	"comment_added",
]);

export type NotifyInput<
	K extends NotificationPayload["kind"] = NotificationPayload["kind"],
> = {
	groupId: string;
	actorUserId: string | null;
	kind: K;
	payload: Extract<NotificationPayload, { kind: K }>;
	toUserIds?: string[];
	toMemberIds?: string[];
	now?: Date;
	enqueue?: EnqueueFn;
	pushEnabled?: boolean;
};

/**
 * Single writer for in-app notifications. Runs inside the caller's open DB transaction.
 */
export async function notify<K extends NotificationPayload["kind"]>(
	executor: DbExecutor,
	input: NotifyInput<K>,
): Promise<Array<{ id: string; userId: string }>> {
	const recipientIds = await resolveNotificationRecipients(executor, {
		groupId: input.groupId,
		actorUserId: input.actorUserId,
		...(input.toUserIds ? { userIds: input.toUserIds } : {}),
		...(input.toMemberIds ? { memberIds: input.toMemberIds } : {}),
	});
	if (recipientIds.length === 0) return [];
	const payload = NotificationPayload.parse(input.payload);
	const createdAt = input.now ?? new Date();
	const inserted = await insertNotificationRows(
		executor,
		recipientIds.map((userId) => ({
			userId,
			groupId: input.groupId,
			kind: input.kind,
			payload,
			createdAt,
		})),
	);
	if (IMMEDIATE_KINDS.has(input.kind) && input.enqueue) {
		for (const row of inserted) {
			await input.enqueue(
				executor,
				JOB_NAMES.sendNotificationMail,
				{ notificationId: row.id },
				{ singletonKey: row.id },
			);
		}
	}
	if (input.pushEnabled && PUSH_KINDS.has(input.kind) && input.enqueue) {
		for (const row of inserted) {
			await input.enqueue(
				executor,
				JOB_NAMES.sendPush,
				{ notificationId: row.id },
				{ singletonKey: row.id },
			);
		}
	}
	return inserted;
}

export async function notifyBudgetWarnings(
	executor: DbExecutor,
	input: {
		groupId: string;
		actorUserId: string;
		actorName: string;
		groupName: string;
		warnings: TransactionWarning[];
		now: Date;
	},
): Promise<void> {
	const state = input.warnings.includes("BUDGET_OVER")
		? "over"
		: input.warnings.includes("BUDGET_NEAR")
			? "near"
			: null;
	if (state === null) return;
	const ownerUserId = await findGroupOwnerUserId(executor, input.groupId);
	if (ownerUserId === null) return;
	await notify(executor, {
		groupId: input.groupId,
		actorUserId: input.actorUserId,
		kind: "budget_state",
		payload: {
			kind: "budget_state",
			actorName: input.actorName,
			groupName: input.groupName,
			state,
		},
		toUserIds: [ownerUserId],
		now: input.now,
	});
}
