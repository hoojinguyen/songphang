import { serve } from "@hono/node-server";
import { createDb, runMigrations } from "@songphang/db";
import { createApp } from "./app.js";
import { type Config, loadConfig } from "./config.js";

let config: Config;
try {
	config = loadConfig(process.env);
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
	const app = createApp({ config, db, now: () => new Date() });
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
	const shutdown = () => server.close(closeDatabase);
	process.once("SIGINT", shutdown);
	process.once("SIGTERM", shutdown);
} catch {
	console.error(
		"API startup failed: check database availability and migrations",
	);
	process.exitCode = 1;
}
