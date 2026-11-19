import path from "node:path";
import { DeleteFilesPayload, JOB_NAMES } from "@songphang/contract";
import type { PgBoss } from "pg-boss";
import { registerJob, type WorkerDeps } from "../queue.js";

export async function registerDeleteFilesJob(
	boss: PgBoss,
	deps: WorkerDeps,
): Promise<void> {
	await registerJob(
		boss,
		JOB_NAMES.deleteFiles,
		DeleteFilesPayload,
		async (data, workerDeps) => {
			const dirs = new Set<string>();
			for (const key of data.keys) {
				await workerDeps.fileStore.delete(key);
				dirs.add(path.posix.dirname(key));
			}
			for (const groupId of dirs) {
				await workerDeps.fileStore.removeEmptyGroupDir(groupId);
			}
		},
		deps,
	);
}
