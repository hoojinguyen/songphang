export type GroupResource =
	| "group"
	| "members"
	| "users"
	| "transactions"
	| "balances"
	| "activity";
export type GroupEvent =
	| { type: "changed"; resources: GroupResource[] }
	| { type: "removed" };
type Subscriber = { userId: string; listener: (event: GroupEvent) => void };
export function createEventHub() {
	const groups = new Map<string, Set<Subscriber>>();
	return {
		subscribe(
			groupId: string,
			userId: string,
			listener: (event: GroupEvent) => void,
		) {
			const subscriber = { userId, listener };
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
