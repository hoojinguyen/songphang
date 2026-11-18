import {
	GroupEventNotification,
	type GroupEventResource,
} from "@songphang/contract";
import { type DbExecutor, drizzleSql } from "@songphang/db";

const CHANNEL_NAME = "songphang_events";
const MAX_PAYLOAD_BYTES = 500;

export async function notifyGroup(
	db: DbExecutor,
	groupId: string,
	resources: GroupEventResource[],
): Promise<void> {
	const validated = GroupEventNotification.parse({ groupId, resources });
	const payload = JSON.stringify(validated);
	if (Buffer.byteLength(payload, "utf8") > MAX_PAYLOAD_BYTES) {
		throw new Error("Notification payload exceeds 500 bytes");
	}
	await db.execute(drizzleSql`SELECT pg_notify(${CHANNEL_NAME}, ${payload})`);
}
