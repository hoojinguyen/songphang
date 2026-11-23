import { JOB_NAMES, SendPushPayload } from "@songphang/contract";
import { formatNotificationText } from "@songphang/core";
import {
	deletePushDeviceIfUnchanged,
	findNotificationForPush,
	listActivePushDevicesForUser,
} from "@songphang/db";
import type { PgBoss } from "pg-boss";
import { sanitizePushTarget } from "../push/types.js";
import { registerJob, type WorkerDeps } from "../queue.js";

// In-memory tracking of delivered devices per notification to prevent duplicate delivery across queue retries.
// Note on provider-accepted vs worker-crash ambiguity:
// If a push was accepted by APNs but the worker process crashes before recording or completing,
// a subsequent retry after restart might re-deliver to that device. In-memory tracking prevents
// duplicate delivery across queue retries within the running worker.
const deliveredNotificationDevices = new Map<string, Set<string>>();
const MAX_TRACKED_NOTIFICATIONS = 10_000;

export async function runSendPush(
	deps: WorkerDeps,
	notificationId: string,
): Promise<number> {
	if (!deps.pushSender) return 0;

	const row = await findNotificationForPush(deps.db, notificationId);
	if (row === null || row.readAt !== null || !row.inGroup || row.muted) {
		return 0;
	}

	const devices = await listActivePushDevicesForUser(deps.db, {
		userId: row.userId,
		now: deps.now(),
	});
	if (devices.length === 0) return 0;

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
	const delivered = deliveredNotificationDevices.get(notificationId);

	for (const device of devices) {
		if (delivered?.has(device.id)) {
			// Already delivered to this device in a previous attempt of this notification
			continue;
		}
		try {
			const result = await deps.pushSender.send(device, {
				title: row.groupName,
				body,
				groupId: row.groupId,
				target,
			});
			if (result === "sent") {
				sentCount += 1;
				let set = deliveredNotificationDevices.get(notificationId);
				if (!set) {
					if (deliveredNotificationDevices.size >= MAX_TRACKED_NOTIFICATIONS) {
						const oldest = deliveredNotificationDevices.keys().next().value;
						if (oldest !== undefined) {
							deliveredNotificationDevices.delete(oldest);
						}
					}
					set = new Set<string>();
					deliveredNotificationDevices.set(notificationId, set);
				}
				set.add(device.id);
			} else if (result === "gone") {
				await deletePushDeviceIfUnchanged(deps.db, {
					id: device.id,
					userId: device.userId,
					sessionId: device.sessionId,
					token: device.token,
					lastSeenAt: device.lastSeenAt,
				});
			} else if (result === "permanent_failure") {
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

	if (hasFailure) {
		throw new Error("Push delivery failed for one or more active devices");
	}
	deliveredNotificationDevices.delete(notificationId);
	return sentCount;
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
