import { HeartbeatPayload, JOB_NAMES } from "@songphang/contract";
import type { PgBoss } from "pg-boss";
import { registerJob, type WorkerDeps } from "../queue.js";

export async function registerHeartbeatJob(
	boss: PgBoss,
	deps: WorkerDeps,
): Promise<void> {
	await registerJob(
		boss,
		JOB_NAMES.heartbeat,
		HeartbeatPayload,
		async (_data, workerDeps) => {
			console.log(
				JSON.stringify({
					event: "worker.heartbeat",
					at: workerDeps.now().toISOString(),
				}),
			);
		},
		deps,
	);
	await boss.schedule(JOB_NAMES.heartbeat, "* * * * *", {});
}
