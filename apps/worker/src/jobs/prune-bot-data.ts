import { JOB_NAMES, PruneBotDataPayload } from "@songphang/contract";
import { pruneBotRecords } from "@songphang/db";
import type { PgBoss } from "pg-boss";
import { registerJob, type WorkerDeps } from "../queue.js";

export async function runPruneBotData(deps: WorkerDeps) {
	return pruneBotRecords(deps.db, deps.now());
}

export async function registerPruneBotDataJob(
	boss: PgBoss,
	deps: WorkerDeps,
): Promise<void> {
	await registerJob(
		boss,
		JOB_NAMES.pruneBotData,
		PruneBotDataPayload,
		async (_data, workerDeps) => {
			await runPruneBotData(workerDeps);
		},
		deps,
	);
	await boss.schedule(
		JOB_NAMES.pruneBotData,
		"0 * * * *",
		{},
		{ tz: "Asia/Ho_Chi_Minh" },
	);
}
