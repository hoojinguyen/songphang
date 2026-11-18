import {
	NotificationPayload,
	type TransactionWarning,
} from "@songphang/contract";
import {
	type DbExecutor,
	findGroupOwnerUserId,
	insertNotificationRows,
	resolveNotificationRecipients,
} from "@songphang/db";

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
	return insertNotificationRows(
		executor,
		recipientIds.map((userId) => ({
			userId,
			groupId: input.groupId,
			kind: input.kind,
			payload,
			createdAt,
		})),
	);
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
