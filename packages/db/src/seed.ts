import { fileURLToPath } from "node:url";
import { sql } from "drizzle-orm";
import { createDb, type Db } from "./client.js";
import { users } from "./schema.js";

export const DEV_USERS: ReadonlyArray<{ email: string; name: string }> = [
	{ email: "minh@dev.songphang.local", name: "Minh" },
	{ email: "lan@dev.songphang.local", name: "Lan" },
	{ email: "hung@dev.songphang.local", name: "Hùng" },
	{ email: "thu@dev.songphang.local", name: "Thu" },
];

export async function seedDevUsers(db: Db): Promise<void> {
	await db.transaction(async (transaction) => {
		for (const user of DEV_USERS) {
			await transaction
				.insert(users)
				.values({ ...user, emailVerifiedAt: sql`now()` })
				.onConflictDoNothing();
		}
	});
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
	try {
		const { db, close } = createDb(process.env.DATABASE_URL ?? "");
		try {
			await seedDevUsers(db);
			console.log("Development users seeded");
		} finally {
			await close();
		}
	} catch {
		console.error("Seed failed: check DATABASE_URL and database migrations");
		process.exitCode = 1;
	}
}
