import { serve } from "@hono/node-server";
import {
	createDb,
	deleteExpiredIdempotencyKeys,
	runMigrations,
} from "@songphang/db";
import { createApp } from "./app.js";
import { type Config, loadConfig } from "./config.js";
import { createConsoleMailer } from "./mailer.js";
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

try {
	await runMigrations(config.databaseUrl);
	const { db, close } = createDb(config.databaseUrl);
	const cleanIdempotencyKeys = () =>
		deleteExpiredIdempotencyKeys(
			db,
			new Date(Date.now() - 24 * 60 * 60 * 1000),
		);
	await cleanIdempotencyKeys();
	const cleanupTimer = setInterval(
		() => {
			cleanIdempotencyKeys().catch(() => {
				console.error("Idempotency cleanup failed");
			});
		},
		60 * 60 * 1000,
	);
	cleanupTimer.unref();
	const app = createApp({
		config,
		db,
		now: () => new Date(),
		mailer: createConsoleMailer(),
		rateLimiter: createRateLimiter(() => new Date()),
	});
	const server = serve(
		{ fetch: app.fetch, port: config.apiPort, hostname: "127.0.0.1" },
		() => {
			console.log(`API listening at http://localhost:${config.apiPort}`);
		},
	);
	const closeDatabase = () =>
		close().catch(() => {
			console.error("Failed to close database connections");
			process.exitCode = 1;
		});
	server.on("error", () => {
		console.error("API server failed");
		server.close(closeDatabase);
		process.exitCode = 1;
	});
	const shutdown = () => {
		clearInterval(cleanupTimer);
		server.close(closeDatabase);
	};
	process.once("SIGINT", shutdown);
	process.once("SIGTERM", shutdown);
} catch {
	console.error(
		"API startup failed: check database availability and migrations",
	);
	process.exitCode = 1;
}
