import type { WorkerConfig } from "../config.js";
import { createApnsPushSender } from "./apns.js";
import { createConsolePushSender } from "./console.js";
import type { PushSender } from "./types.js";

export type { PushDeliveryResult, PushMessage, PushSender } from "./types.js";
export { sanitizePushTarget } from "./types.js";

export function createPushSender(
	config: WorkerConfig,
	now: () => Date,
): PushSender | null {
	if (!config.pushProvider) return null;
	if (config.pushProvider === "console") {
		return createConsolePushSender();
	}
	if (
		!config.appleBundleId ||
		!config.appleTeamId ||
		!config.apnsKeyId ||
		!config.apnsPrivateKey
	) {
		throw new Error("APNs configuration is incomplete");
	}
	return createApnsPushSender({
		bundleId: config.appleBundleId,
		teamId: config.appleTeamId,
		keyId: config.apnsKeyId,
		privateKey: config.apnsPrivateKey,
		now,
	});
}
