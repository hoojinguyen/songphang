import type { ActivePushDevice } from "@songphang/db";

export type PushDeliveryResult =
	| "sent"
	| "gone"
	| "failed"
	| "permanent_failure";

export type PushMessage = {
	title: string;
	body: string;
	groupId: string;
	target: string;
};

export type PushSender = {
	send(
		device: ActivePushDevice,
		message: PushMessage,
	): Promise<PushDeliveryResult>;
	close?: () => Promise<void>;
};

const ALLOWED_PUSH_TARGET =
	/^\/g\/[0-9a-f-]{36}(?:\/(?:balances|stats|tx\/[0-9a-f-]{36}\/view))?$/;

export function sanitizePushTarget(groupId: string, href: string): string {
	if (ALLOWED_PUSH_TARGET.test(href) && href.startsWith(`/g/${groupId}`)) {
		return href;
	}
	return `/g/${groupId}`;
}
