import { createDb, runMigrations } from "@songphang/db";
import { diskFileStore } from "@songphang/storage";
import { loadWorkerConfig, type WorkerConfig } from "./config.js";
import { registerAutoRemindersJob } from "./jobs/auto-reminders.js";
import { registerCleanupAttachmentsJob } from "./jobs/cleanup-attachments.js";
import { registerDeleteFilesJob } from "./jobs/delete-files.js";
import { registerHeartbeatJob } from "./jobs/heartbeat.js";
import { registerPruneBotDataJob } from "./jobs/prune-bot-data.js";
import { registerPruneNotificationsJob } from "./jobs/prune-notifications.js";
import {
	recoverStaleScans,
	registerReadReceiptJob,
} from "./jobs/read-receipt.js";
import { registerSendDigestJob } from "./jobs/send-digest.js";
import { registerSendNotificationMailJob } from "./jobs/send-notification-mail.js";
import { registerSendPushJob } from "./jobs/send-push.js";
import { createConsoleMailer } from "./mailer.js";
import { createPushSender } from "./push/index.js";
import {
	createWorkerEnqueue,
	createWorkerQueue,
	type WorkerDeps,
} from "./queue.js";

let config: WorkerConfig;
try {
	config = loadWorkerConfig(process.env);
	if (config.appEnv === "production") {
		throw new Error("Mailer is not configured for production");
	}
} catch (error) {
	console.error(
		error instanceof Error
			? error.message
			: "Invalid environment configuration",
	);
	process.exit(1);
}

let closeDb: (() => Promise<void>) | null = null;
let stopBoss: (() => Promise<void>) | null = null;
try {
	await runMigrations(config.databaseUrl);
	const { db, close } = createDb(config.databaseUrl);
	closeDb = close;
	const boss = createWorkerQueue(config.databaseUrl);
	boss.on("error", () => {
		console.error("Worker queue error");
	});
	await boss.start();
	stopBoss = () => boss.stop({ graceful: false });
	const pushSender = createPushSender(config, () => new Date());
	const deps: WorkerDeps = {
		config,
		db,
		fileStore: diskFileStore(config.storageDir),
		now: () => new Date(),
		mailer: createConsoleMailer(),
		pushSender,
		enqueue: createWorkerEnqueue(boss),
	};
	await registerHeartbeatJob(boss, deps);
	await registerCleanupAttachmentsJob(boss, deps);
	await registerDeleteFilesJob(boss, deps);
	await registerReadReceiptJob(boss, deps);
	await registerSendNotificationMailJob(boss, deps);
	await registerSendPushJob(boss, deps);
	await registerSendDigestJob(boss, deps);
	await registerPruneNotificationsJob(boss, deps);
	await registerAutoRemindersJob(boss, deps);
	await registerPruneBotDataJob(boss, deps);
	await recoverStaleScans(deps);
	const recoveryTimer = setInterval(() => {
		void recoverStaleScans(deps).catch(() => {
			console.error("Failed to recover stale receipt scans");
		});
	}, 60_000);
	console.log(JSON.stringify({ event: "worker.started" }));

	const shutdown = async () => {
		clearInterval(recoveryTimer);
		await pushSender?.close?.().catch(() => {
			console.error("Failed to close push sender");
		});
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
	if (stopBoss !== null) {
		await stopBoss().catch(() => {});
	}
	if (closeDb !== null) {
		await closeDb().catch(() => {});
	}
	console.error(
		"Worker startup failed: check database availability and migrations",
	);
	process.exitCode = 1;
}
