import { drizzle, type PostgresJsDatabase } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import { z } from "zod";
import * as schema from "./schema.js";

export type DbExecutor = Db | Parameters<Parameters<Db["transaction"]>[0]>[0];

export type Db = PostgresJsDatabase<typeof schema>;

const DATABASE_URL_SCHEMA = z
	.url({ protocol: /^postgres(ql)?$/, hostname: /.+/ })
	.max(8192);

export function createDb(url: string): { db: Db; close(): Promise<void> } {
	const result = DATABASE_URL_SCHEMA.safeParse(url);
	if (!result.success) {
		throw new Error("DATABASE_URL must be a valid PostgreSQL URL");
	}
	const client = postgres(result.data, { connect_timeout: 5 });
	return {
		db: drizzle(client, { schema }),
		close: () => client.end({ timeout: 5 }),
	};
}

export async function checkDatabaseHealth(db: Db): Promise<boolean> {
	let timeout: ReturnType<typeof setTimeout> | undefined;
	try {
		return await Promise.race([
			db.execute("select 1").then(
				() => true,
				() => false,
			),
			new Promise<boolean>((resolve) => {
				timeout = setTimeout(() => resolve(false), 2000);
			}),
		]);
	} finally {
		clearTimeout(timeout);
	}
}
