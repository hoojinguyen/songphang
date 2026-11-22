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
	for (const device of devices) {
		const result = await deps.pushSender.send(device, {
			title: row.groupName,
			body,
			groupId: row.groupId,
			target,
		});
		if (result === "sent") {
			sentCount += 1;
		} else if (result === "gone") {
			await deletePushDeviceIfUnchanged(deps.db, {
				id: device.id,
				userId: device.userId,
				sessionId: device.sessionId,
				token: device.token,
				lastSeenAt: device.lastSeenAt,
			});
		} else {
			hasFailure = true;
		}
	}

	if (hasFailure) {
		throw new Error("Push delivery failed for one or more active devices");
	}
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
