import { JOB_NAMES, SendPushPayload } from "@songphang/contract";
import { formatNotificationText } from "@songphang/core";
import {
	type DbExecutor,
	deletePushDeviceIfUnchanged,
	findNotificationForPush,
	listActivePushDevicesForUser,
	lockPushDelivery,
	recordPushDeviceDelivered,
} from "@songphang/db";
import type { PgBoss } from "pg-boss";
import { sanitizePushTarget } from "../push/types.js";
import { registerJob, type WorkerDeps } from "../queue.js";

export async function runSendPush(
	deps: WorkerDeps,
	notificationId: string,
): Promise<number> {
	const pushSender = deps.pushSender;
	if (!pushSender) return 0;

	const outcome = await deps.db.transaction(async (transaction) => {
		await lockPushDelivery(transaction, notificationId);
		return deliverNotification(
			transaction,
			pushSender,
			notificationId,
			deps.now(),
		);
	});
	if (outcome.hasFailure) {
		throw new Error("Push delivery failed for one or more active devices");
	}
	return outcome.sentCount;
}

async function deliverNotification(
	executor: DbExecutor,
	pushSender: NonNullable<WorkerDeps["pushSender"]>,
	notificationId: string,
	now: Date,
): Promise<{ sentCount: number; hasFailure: boolean }> {
	const row = await findNotificationForPush(executor, notificationId);
	if (row === null || row.readAt !== null || !row.inGroup || row.muted) {
		return { sentCount: 0, hasFailure: false };
	}

	const devices = await listActivePushDevicesForUser(executor, {
		userId: row.userId,
		now,
	});
	if (devices.length === 0) return { sentCount: 0, hasFailure: false };

	const { text, href } = formatNotificationText({
		groupId: row.groupId,
		kind: row.kind,
		payload: row.payload,
	});
	const body = row.hidePushContent
		? `Có cập nhật trong nhóm ${row.groupName}`
		: text;
	const target = sanitizePushTarget(row.groupId, href);

	let sentCount = 0;
	let hasFailure = false;
	const payloadObj =
		typeof row.payload === "object" && row.payload !== null
			? (row.payload as Record<string, unknown>)
			: null;
	const durableDeliveredIds = new Set<string>(
		Array.isArray(payloadObj?._deliveredDeviceIds)
			? payloadObj._deliveredDeviceIds.filter(
					(id): id is string => typeof id === "string",
				)
			: [],
	);

	for (const device of devices) {
		if (durableDeliveredIds.has(device.id)) {
			// Already delivered to this device in a previous attempt of this notification
			continue;
		}
		try {
			const result = await pushSender.send(device, {
				title: row.groupName,
				body,
				groupId: row.groupId,
				target,
			});
			if (result === "sent") {
				sentCount += 1;
				await recordPushDeviceDelivered(executor, notificationId, device.id);
			} else if (result === "gone") {
				await recordPushDeviceDelivered(executor, notificationId, device.id);
				await deletePushDeviceIfUnchanged(executor, {
					id: device.id,
					userId: device.userId,
					sessionId: device.sessionId,
					token: device.token,
					lastSeenAt: device.lastSeenAt,
				});
			} else if (result === "permanent_failure") {
				await recordPushDeviceDelivered(executor, notificationId, device.id);
				console.warn(
					JSON.stringify({
						event: "push.send.permanent_failure",
						deviceId: device.id,
					}),
				);
			} else {
				hasFailure = true;
			}
		} catch (error) {
			console.warn(
				JSON.stringify({
					event: "push.send.device_exception",
					deviceId: device.id,
					category: error instanceof Error ? error.name : "unknown",
				}),
			);
			hasFailure = true;
		}
	}

	return { sentCount, hasFailure };
}

export async function registerSendPushJob(
	boss: PgBoss,
	deps: WorkerDeps,
): Promise<void> {
	await registerJob(
		boss,
		JOB_NAMES.sendPush,
		SendPushPayload,
		async (data, workerDeps) => {
			await runSendPush(workerDeps, data.notificationId);
		},
		deps,
	);
}
