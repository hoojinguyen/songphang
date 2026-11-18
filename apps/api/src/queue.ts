import { JOB_NAMES } from "@songphang/contract";
import { type DbExecutor, drizzleSql } from "@songphang/db";
import { fromDrizzle, PgBoss } from "pg-boss";

export type EnqueueFn = <T extends object>(
	executor: DbExecutor,
	name: string,
	data: T,
	options?: { singletonKey?: string; startAfter?: Date },
) => Promise<string | null>;

export function createApiQueue(connectionString: string): {
	start(): Promise<void>;
	enqueue: EnqueueFn;
	stop(): Promise<void>;
} {
	const boss = new PgBoss({
		connectionString,
		supervise: false,
		schedule: false,
		registerInstance: false,
	});
	boss.on("error", () => {
		console.error("API queue error");
	});
	return {
		async start() {
			await boss.start();
			for (const name of Object.values(JOB_NAMES)) {
				await boss.createQueue(name);
			}
		},
		enqueue: async (executor, name, data, options) => {
			return boss.send(name, data, {
				db: fromDrizzle(executor, drizzleSql),
				...(options?.singletonKey
					? { singletonKey: options.singletonKey }
					: {}),
				...(options?.startAfter ? { startAfter: options.startAfter } : {}),
			});
		},
		async stop() {
			await boss.stop({ graceful: false });
		},
	};
}
