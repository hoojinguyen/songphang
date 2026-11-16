type Snapshot = { online: boolean; since: number | null };
let failed = false;
let snapshot: Snapshot = {
	online: typeof navigator === "undefined" ? true : navigator.onLine,
	since:
		typeof navigator !== "undefined" && !navigator.onLine ? Date.now() : null,
};
const listeners = new Set<() => void>();
function update() {
	const online =
		(typeof navigator === "undefined" || navigator.onLine) && !failed;
	if (snapshot.online === online) return;
	snapshot = { online, since: online ? null : Date.now() };
	for (const listener of listeners) listener();
}
export function requestFailed() {
	failed = true;
	update();
}
export function requestSucceeded() {
	failed = false;
	update();
}
export function connectionSnapshot() {
	return snapshot;
}
const serverSnapshot: Snapshot = { online: true, since: null };
export function connectionServerSnapshot() {
	return serverSnapshot;
}
export function subscribeConnection(listener: () => void) {
	listeners.add(listener);
	const online = () => {
		failed = false;
		update();
	};
	const offline = () => update();
	window.addEventListener("online", online);
	window.addEventListener("offline", offline);
	update();
	return () => {
		listeners.delete(listener);
		window.removeEventListener("online", online);
		window.removeEventListener("offline", offline);
	};
}
