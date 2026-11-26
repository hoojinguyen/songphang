import { z } from "@hono/zod-openapi";
import {
	CalendarDate,
	JOB_NAMES,
	MoneyAmount,
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

export const ExtendedNotificationPayload = z.union([
	NotificationPayload,
	z.object({
		kind: z.literal("recurring_posted"),
		groupName: z.string(),
		transactionId: z.uuid(),
		description: z.string(),
		amount: MoneyAmount,
		share: z.int().nonnegative(),
	}),
	z.object({
		kind: z.literal("recurring_due"),
		groupName: z.string(),
		recurringExpenseId: z.uuid(),
		description: z.string(),
		dueDate: CalendarDate,
	}),
]);
export type ExtendedNotificationPayload = z.infer<
	typeof ExtendedNotificationPayload
>;

const IMMEDIATE_KINDS = new Set<ExtendedNotificationPayload["kind"]>([
	"dispute_opened",
	"dispute_resolved",
	"settlement_requested",
	"settlement_confirmed",
	"settlement_rejected",
	"debt_reminder",
	"approval_requested",
	"approval_decided",
	"recurring_due",
]);

const PUSH_KINDS = new Set<ExtendedNotificationPayload["kind"]>([
	...IMMEDIATE_KINDS,
	"expense_added",
	"comment_added",
	"recurring_posted",
]);

export type NotifyInput<
	K extends
		ExtendedNotificationPayload["kind"] = ExtendedNotificationPayload["kind"],
> = {
	groupId: string;
	actorUserId: string | null;
	kind: K;
	payload: Extract<ExtendedNotificationPayload, { kind: K }>;
	toUserIds?: string[];
	toMemberIds?: string[];
	now?: Date;
	enqueue?: EnqueueFn;
	pushEnabled?: boolean;
};

/**
 * Single writer for in-app notifications. Runs inside the caller's open DB transaction.
 */
export async function notify<K extends ExtendedNotificationPayload["kind"]>(
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
	const payload = ExtendedNotificationPayload.parse(input.payload);
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
