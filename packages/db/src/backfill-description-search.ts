import { fileURLToPath } from "node:url";
import { foldVietnamese } from "@songphang/core";
import { eq } from "drizzle-orm";
import { createDb, type Db } from "./client.js";
import { transactions } from "./schema-transactions.js";

export async function backfillDescriptionSearch(db: Db): Promise<number> {
	const rows = await db
		.select({
			id: transactions.id,
			description: transactions.description,
			descriptionSearch: transactions.descriptionSearch,
		})
		.from(transactions);
	let updated = 0;
	for (const row of rows) {
		const normalized = foldVietnamese(row.description);
		if (row.descriptionSearch === normalized) continue;
		await db
			.update(transactions)
			.set({ descriptionSearch: normalized })
			.where(eq(transactions.id, row.id));
		updated += 1;
	}
	return updated;
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
	void (async () => {
		const { db, close } = createDb(process.env.DATABASE_URL ?? "");
		try {
			const count = await backfillDescriptionSearch(db);
			console.log(`Backfilled description_search on ${count} rows`);
		} finally {
			await close();
		}
	})();
}
