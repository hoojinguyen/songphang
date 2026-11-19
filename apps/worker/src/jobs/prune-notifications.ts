import { JOB_NAMES, PruneNotificationsPayload } from "@songphang/contract";
import { deleteOldNotifications } from "@songphang/db";
import type { PgBoss } from "pg-boss";
import { registerJob, type WorkerDeps } from "../queue.js";

const RETENTION_MS = 90 * 24 * 60 * 60 * 1000;

export async function runPruneNotifications(deps: WorkerDeps): Promise<number> {
	const cutoff = new Date(deps.now().getTime() - RETENTION_MS);
	return deleteOldNotifications(deps.db, cutoff);
}

export async function registerPruneNotificationsJob(
	boss: PgBoss,
	deps: WorkerDeps,
): Promise<void> {
	await registerJob(
		boss,
		JOB_NAMES.pruneNotifications,
		PruneNotificationsPayload,
		async (_data, workerDeps) => {
			await runPruneNotifications(workerDeps);
		},
		deps,
	);
	await boss.schedule(
		JOB_NAMES.pruneNotifications,
		"15 3 * * *",
		{},
		{ tz: "Asia/Ho_Chi_Minh" },
	);
}
