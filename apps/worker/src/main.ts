import { createDb, runMigrations } from "@songphang/db";
import { diskFileStore } from "@songphang/storage";
import { loadWorkerConfig, type WorkerConfig } from "./config.js";
import { registerCleanupAttachmentsJob } from "./jobs/cleanup-attachments.js";
import { registerDeleteFilesJob } from "./jobs/delete-files.js";
import { registerHeartbeatJob } from "./jobs/heartbeat.js";
import { createWorkerQueue, type WorkerDeps } from "./queue.js";

let config: WorkerConfig;
try {
	config = loadWorkerConfig(process.env);
} catch (error) {
	console.error(
		error instanceof Error
			? error.message
			: "Invalid environment configuration",
	);
	process.exit(1);
}

try {
	await runMigrations(config.databaseUrl);
	const { db, close } = createDb(config.databaseUrl);
	const boss = createWorkerQueue(config.databaseUrl);
	boss.on("error", () => {
		console.error("Worker queue error");
	});
	await boss.start();
	const deps: WorkerDeps = {
		config,
		db,
		fileStore: diskFileStore(config.storageDir),
		now: () => new Date(),
	};
	await registerHeartbeatJob(boss, deps);
	await registerCleanupAttachmentsJob(boss, deps);
	await registerDeleteFilesJob(boss, deps);
	console.log(JSON.stringify({ event: "worker.started" }));

	const shutdown = async () => {
		await boss.stop({ graceful: true }).catch(() => {
			console.error("Failed to stop worker queue");
			process.exitCode = 1;
		});
		await close().catch(() => {
			console.error("Failed to close database connections");
			process.exitCode = 1;
		});
	};
	process.once("SIGINT", () => {
		void shutdown();
	});
	process.once("SIGTERM", () => {
		void shutdown();
	});
} catch {
	console.error(
		"Worker startup failed: check database availability and migrations",
	);
	process.exitCode = 1;
}
