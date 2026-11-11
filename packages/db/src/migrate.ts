import { fileURLToPath } from "node:url";
import { migrate } from "drizzle-orm/postgres-js/migrator";
import { createDb } from "./client.js";

export async function runMigrations(url: string): Promise<void> {
	const { db, close } = createDb(url);
	try {
		await migrate(db, {
			migrationsFolder: fileURLToPath(new URL("../drizzle", import.meta.url)),
		});
	} finally {
		await close();
	}
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
	try {
		await runMigrations(process.env.DATABASE_URL ?? "");
		console.log("Migrations applied");
	} catch {
		console.error(
			"Migration failed: check DATABASE_URL and database availability",
		);
		process.exitCode = 1;
	}
}
