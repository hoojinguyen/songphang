import { CleanupAttachmentsPayload, JOB_NAMES } from "@songphang/contract";
import {
	deleteStaleUnattachedForGroup,
	findAttachmentByStorageKey,
	findGroup,
	listStaleUnattachedGroups,
	lockGroup,
} from "@songphang/db";
import type { PgBoss } from "pg-boss";
import { registerJob, type WorkerDeps } from "../queue.js";

const ORPHAN_AGE_MS = 24 * 60 * 60 * 1000;

async function cleanupDiskForGroup(
	deps: WorkerDeps,
	groupId: string,
	cutoffMs: number,
): Promise<void> {
	const files = await deps.fileStore.listGroupFiles(groupId);
	const stale = files.filter((file) => file.mtimeMs < cutoffMs);
	if (stale.length === 0) return;

	await deps.db.transaction(async (executor) => {
		const group = await findGroup(executor, groupId);
		if (group !== null) {
			await lockGroup(executor, groupId);
		}
		for (const file of stale) {
			if (file.name.includes(".tmp-")) {
				await deps.fileStore.deleteGroupFile(groupId, file.name);
				continue;
			}
			const existing =
				group === null
					? null
					: await findAttachmentByStorageKey(
							executor,
							`${groupId}/${file.name}`,
						);
			if (existing === null) {
				await deps.fileStore.deleteGroupFile(groupId, file.name);
			}
		}
	});
	await deps.fileStore.removeEmptyGroupDir(groupId);
}

export async function runCleanupAttachments(deps: WorkerDeps): Promise<void> {
	const cutoff = new Date(deps.now().getTime() - ORPHAN_AGE_MS);
	const groupIds = await listStaleUnattachedGroups(deps.db, cutoff);
	for (const groupId of groupIds) {
		const keys = await deps.db.transaction(async (executor) => {
			const group = await findGroup(executor, groupId);
			if (group === null) return [];
			await lockGroup(executor, groupId);
			return deleteStaleUnattachedForGroup(executor, groupId, cutoff);
		});
		await Promise.allSettled(keys.map((key) => deps.fileStore.delete(key)));
	}
	const diskGroups = await deps.fileStore.listGroupDirs();
	for (const groupId of diskGroups) {
		await cleanupDiskForGroup(deps, groupId, cutoff.getTime());
	}
}

export async function registerCleanupAttachmentsJob(
	boss: PgBoss,
	deps: WorkerDeps,
): Promise<void> {
	await registerJob(
		boss,
		JOB_NAMES.cleanupAttachments,
		CleanupAttachmentsPayload,
		async (_data, workerDeps) => {
			await runCleanupAttachments(workerDeps);
		},
		deps,
	);
	await boss.schedule(
		JOB_NAMES.cleanupAttachments,
		"30 3 * * *",
		{},
		{ tz: "Asia/Ho_Chi_Minh" },
	);
}
