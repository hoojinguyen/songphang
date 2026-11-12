import type { DbExecutor } from "./client.js";
import { activityLog } from "./schema-records.js";
export function insertActivity(
	executor: DbExecutor,
	input: typeof activityLog.$inferInsert,
) {
	return executor.insert(activityLog).values(input);
}
