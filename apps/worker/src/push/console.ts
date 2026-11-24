import type { PushSender } from "./types.js";

export function createConsolePushSender(): PushSender {
	return {
		async send(device, message) {
			console.log(
				JSON.stringify({
					event: "push.sent.console",
					deviceId: device.id,
					platform: device.platform,
					environment: device.environment,
					groupId: message.groupId,
					target: message.target,
					title: message.title,
					body: message.body,
				}),
			);
			return "sent";
		},
	};
}
