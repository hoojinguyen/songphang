export type GroupResource =
	| "group"
	| "members"
	| "users"
	| "transactions"
	| "balances"
	| "activity"
	| "settlementRequests"
	| "categories"
	| "budget";
export type GroupEvent =
	| { type: "changed"; resources: GroupResource[] }
	| { type: "removed" }
	| { type: "revoked" };
type Subscriber = {
	userId: string;
	tokenHash: string;
	listener: (event: GroupEvent) => void;
};
export function createEventHub() {
	const groups = new Map<string, Set<Subscriber>>();
	const revoke = (matches: (subscriber: Subscriber) => boolean) => {
		for (const [groupId, listeners] of groups) {
			for (const subscriber of listeners)
				if (matches(subscriber)) {
					listeners.delete(subscriber);
					subscriber.listener({ type: "revoked" });
				}
			if (listeners.size === 0) groups.delete(groupId);
		}
	};
	return {
		revokeSession(tokenHash: string) {
			revoke((subscriber) => subscriber.tokenHash === tokenHash);
		},
		revokeUserSessions(userId: string, keepTokenHash?: string) {
			revoke(
				(subscriber) =>
					subscriber.userId === userId &&
					subscriber.tokenHash !== keepTokenHash,
			);
		},
		subscribe(
			input: { groupId: string; userId: string; tokenHash: string },
			listener: (event: GroupEvent) => void,
		) {
			const { groupId, userId, tokenHash } = input;
			const subscriber = { userId, listener, tokenHash };
			const listeners = groups.get(groupId) ?? new Set<Subscriber>();
			groups.set(groupId, listeners);
			listeners.add(subscriber);
			return () => {
				listeners.delete(subscriber);
				if (listeners.size === 0 && groups.get(groupId) === listeners)
					groups.delete(groupId);
			};
		},
		publishChanged(groupId: string, resources: GroupResource[]) {
			for (const subscriber of groups.get(groupId) ?? [])
				subscriber.listener({ type: "changed", resources });
		},
		publishRemoved(groupId: string, userId: string | null) {
			const listeners = groups.get(groupId);
			if (!listeners) return;
			for (const subscriber of listeners)
				if (userId === null || subscriber.userId === userId) {
					listeners.delete(subscriber);
					subscriber.listener({ type: "removed" });
				}
			if (listeners.size === 0) groups.delete(groupId);
		},
	};
}
