import { serve } from "@hono/node-server";
import {
	createDb,
	deleteExpiredIdempotencyKeys,
	runMigrations,
} from "@songphang/db";
import { diskFileStore } from "@songphang/storage";
import { createApp } from "./app.js";
import { createChatSender } from "./bot/chat-sender.js";
import { type Config, loadConfig } from "./config.js";
import { createEventHub } from "./events/hub.js";
import { listenForGroupEvents } from "./events/listen.js";
import { createConsoleMailer } from "./mailer.js";
import { createApiQueue } from "./queue.js";
import { createRateLimiter } from "./rate-limit.js";

let config: Config;
try {
	config = loadConfig(process.env);
	if (config.appEnv === "production")
		throw new Error("Mailer is not configured for production");
} catch (error) {
	console.error(
		error instanceof Error
			? error.message
			: "Invalid environment configuration",
	);
	process.exit(1);
}

let closeDb: (() => Promise<void>) | null = null;
let stopQueue: (() => Promise<void>) | null = null;
let stopEvents: (() => Promise<void>) | null = null;
let cleanupTimer: ReturnType<typeof setInterval> | null = null;
try {
	await runMigrations(config.databaseUrl);
	const { db, close } = createDb(config.databaseUrl);
	closeDb = close;
	const events = createEventHub();
	const queue = createApiQueue(config.databaseUrl);
	await queue.start();
	stopQueue = () => queue.stop();
	const eventListener = listenForGroupEvents(config.databaseUrl, events);
	stopEvents = () => eventListener.stop();
	const cleanIdempotencyKeys = () =>
		deleteExpiredIdempotencyKeys(
			db,
			new Date(Date.now() - 24 * 60 * 60 * 1000),
		);
	await cleanIdempotencyKeys();
	cleanupTimer = setInterval(
		() => {
			cleanIdempotencyKeys().catch(() => {
				console.error("Idempotency cleanup failed");
			});
		},
		60 * 60 * 1000,
	);
	cleanupTimer.unref();
	const app = createApp({
		events,
		config,
		db,
		now: () => new Date(),
		mailer: createConsoleMailer(),
		rateLimiter: createRateLimiter(() => new Date()),
		enqueue: queue.enqueue,
		fileStore: diskFileStore(config.storageDir),
		chatSender: createChatSender(config),
	});
	const server = serve(
		{ fetch: app.fetch, port: config.apiPort, hostname: "127.0.0.1" },
		() => {
			console.log(`API listening at http://localhost:${config.apiPort}`);
		},
	);
	const closeDatabase = () =>
		Promise.allSettled([eventListener.stop(), queue.stop()])
			.then(() => close())
			.catch(() => {
				console.error("Failed to close database connections");
				process.exitCode = 1;
			});
	server.on("error", () => {
		console.error("API server failed");
		server.close(closeDatabase);
		process.exitCode = 1;
	});
	const shutdown = () => {
		if (cleanupTimer !== null) clearInterval(cleanupTimer);
		server.close(closeDatabase);
	};
	process.once("SIGINT", shutdown);
	process.once("SIGTERM", shutdown);
} catch {
	if (cleanupTimer !== null) clearInterval(cleanupTimer);
	await Promise.allSettled([
		stopEvents ? stopEvents() : Promise.resolve(),
		stopQueue ? stopQueue() : Promise.resolve(),
	]);
	if (closeDb !== null) {
		await closeDb().catch(() => {});
	}
	console.error(
		"API startup failed: check database availability and migrations",
	);
	process.exitCode = 1;
}
