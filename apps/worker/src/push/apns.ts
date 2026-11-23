import http2 from "node:http2";
import type { ActivePushDevice } from "@songphang/db";
import { createApnsProviderTokenSource } from "./apns-token.js";
import type { PushDeliveryResult, PushMessage, PushSender } from "./types.js";

const REQUEST_TIMEOUT_MS = 10_000;

function apnsAuthority(environment: ActivePushDevice["environment"]): string {
	return environment === "production"
		? "https://api.push.apple.com"
		: "https://api.sandbox.push.apple.com";
}

function parseApnsReason(body: string): string | null {
	try {
		const parsed = JSON.parse(body) as { reason?: unknown };
		return typeof parsed.reason === "string" ? parsed.reason : null;
	} catch {
		return null;
	}
}

export function createApnsPushSender(input: {
	bundleId: string;
	teamId: string;
	keyId: string;
	privateKey: string;
	now: () => Date;
}): PushSender {
	const tokenSource = createApnsProviderTokenSource({
		teamId: input.teamId,
		keyId: input.keyId,
		privateKey: input.privateKey,
		now: input.now,
	});
	const sessions = new Map<string, http2.ClientHttp2Session>();

	function getSession(authority: string): http2.ClientHttp2Session {
		const existing = sessions.get(authority);
		if (existing && !existing.closed && !existing.destroyed) {
			return existing;
		}
		const client = http2.connect(authority);
		client.on("error", () => {
			if (sessions.get(authority) === client) sessions.delete(authority);
		});
		client.on("close", () => {
			if (sessions.get(authority) === client) sessions.delete(authority);
		});
		sessions.set(authority, client);
		return client;
	}

	return {
		async send(
			device: ActivePushDevice,
			message: PushMessage,
		): Promise<PushDeliveryResult> {
			if (device.platform !== "ios") {
				console.warn(
					JSON.stringify({
						event: "push.send.unsupported_platform",
						platform: device.platform,
						deviceId: device.id,
					}),
				);
				return "permanent_failure";
			}
			const authority = apnsAuthority(device.environment);
			const client = getSession(authority);
			const jwt = tokenSource.getToken();
			const payload = JSON.stringify({
				aps: {
					alert: {
						title: message.title,
						body: message.body,
					},
					sound: "default",
				},
				groupId: message.groupId,
				target: message.target,
			});

			return new Promise<PushDeliveryResult>((resolve) => {
				let settled = false;
				const finish = (result: PushDeliveryResult) => {
					if (settled) return;
					settled = true;
					resolve(result);
				};

				const request = client.request({
					":method": "POST",
					":path": `/3/device/${encodeURIComponent(device.token)}`,
					authorization: `bearer ${jwt}`,
					"apns-topic": input.bundleId,
					"apns-push-type": "alert",
					"apns-priority": "10",
					"content-type": "application/json",
				});

				let status = 0;
				const chunks: Buffer[] = [];

				request.setTimeout(REQUEST_TIMEOUT_MS, () => {
					request.close();
					finish("failed");
				});

				request.on("response", (headers) => {
					const rawStatus = headers[":status"];
					status =
						typeof rawStatus === "number" ? rawStatus : Number(rawStatus);
				});

				request.on("data", (chunk: Buffer | string) => {
					chunks.push(typeof chunk === "string" ? Buffer.from(chunk) : chunk);
				});

				request.on("end", () => {
					if (status === 200) {
						finish("sent");
						return;
					}
					if (status === 403) {
						tokenSource.invalidate();
					}
					const bodyText = Buffer.concat(chunks).toString("utf8");
					const reason = parseApnsReason(bodyText);
					if (status === 410 || (status === 400 && reason === "Unregistered")) {
						finish("gone");
						return;
					}
					if (status === 400 && reason === "BadDeviceToken") {
						finish("permanent_failure");
						return;
					}
					finish("failed");
				});

				request.on("error", () => {
					finish("failed");
				});

				request.end(payload);
			});
		},

		async close(): Promise<void> {
			await Promise.allSettled(
				[...sessions.values()].map(
					(session) =>
						new Promise<void>((resolve) => {
							if (session.closed) {
								resolve();
								return;
							}
							session.close(resolve);
						}),
				),
			);
			sessions.clear();
		},
	};
}
