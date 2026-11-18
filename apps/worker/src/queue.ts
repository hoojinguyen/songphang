import type { Db } from "@songphang/db";
import type { FileStore } from "@songphang/storage";
import { PgBoss } from "pg-boss";
import type { ZodType } from "zod";
import type { ReceiptReader } from "./ai/receipt-reader.js";
import type { WorkerConfig } from "./config.js";
import type { Mailer } from "./mailer.js";

export type WorkerDeps = {
	config: WorkerConfig;
	db: Db;
	fileStore: FileStore;
	now: () => Date;
	receiptReader?: ReceiptReader | null;
	mailer?: Mailer;
};

export function createWorkerQueue(connectionString: string): PgBoss {
	return new PgBoss({
		connectionString,
		registerInstance: false,
	});
}

export async function registerJob<T>(
	boss: PgBoss,
	name: string,
	schema: ZodType<T>,
	handler: (data: T, deps: WorkerDeps) => Promise<void>,
	deps: WorkerDeps,
): Promise<void> {
	await boss.createQueue(name);
	await boss.work(name, async (jobs) => {
		for (const job of jobs) {
			const parsed = schema.safeParse(job.data ?? {});
			if (!parsed.success) {
				throw new Error(`Invalid job payload for ${name}`);
			}
			await handler(parsed.data, deps);
		}
	});
}
