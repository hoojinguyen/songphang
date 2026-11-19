import { GroupEventNotification } from "@songphang/contract";
import { listenPgChannel } from "@songphang/db";
import type { createEventHub } from "./hub.js";

const CHANNEL_NAME = "songphang_events";
const MAX_BACKOFF_MS = 30_000;

export function listenForGroupEvents(
	connectionString: string,
	hub: ReturnType<typeof createEventHub>,
): { stop(): Promise<void> } {
	let stopped = false;
	let currentClose: (() => Promise<void>) | null = null;
	let retryTimer: ReturnType<typeof setTimeout> | null = null;

	const handlePayload = (raw: string) => {
		let parsedJson: unknown;
		try {
			parsedJson = JSON.parse(raw);
		} catch {
			console.warn("Ignoring malformed group event notification");
			return;
		}
		const result = GroupEventNotification.safeParse(parsedJson);
		if (!result.success) {
			console.warn("Ignoring invalid group event notification");
			return;
		}
		hub.publishChanged(result.data.groupId, result.data.resources);
	};

	const connect = (attempt: number) => {
		if (stopped) return;
		const listener = listenPgChannel(
			connectionString,
			CHANNEL_NAME,
			handlePayload,
		);
		currentClose = listener.close;
		listener.ready.catch(() => {
			void listener.close().catch(() => {});
			if (stopped) return;
			const delayMs = Math.min(1000 * 2 ** attempt, MAX_BACKOFF_MS);
			console.warn(
				`Group event listener disconnected; retrying in ${delayMs}ms`,
			);
			retryTimer = setTimeout(() => {
				retryTimer = null;
				connect(attempt + 1);
			}, delayMs);
			retryTimer.unref();
		});
	};

	connect(0);

	return {
		async stop() {
			stopped = true;
			if (retryTimer) {
				clearTimeout(retryTimer);
				retryTimer = null;
			}
			if (currentClose) {
				await currentClose().catch(() => {});
			}
		},
	};
}
