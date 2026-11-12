import { and, eq, lt } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { idempotencyKeys } from "./schema-records.js";
export async function findIdempotencyKey(
	executor: DbExecutor,
	userId: string,
	key: string,
) {
	const [stored] = await executor
		.select({
			requestHash: idempotencyKeys.requestHash,
			status: idempotencyKeys.responseStatus,
			body: idempotencyKeys.responseBody,
			createdAt: idempotencyKeys.createdAt,
		})
		.from(idempotencyKeys)
		.where(
			and(eq(idempotencyKeys.userId, userId), eq(idempotencyKeys.key, key)),
		)
		.limit(1);
	return stored ?? null;
}
export function insertIdempotencyKey(
	executor: DbExecutor,
	input: typeof idempotencyKeys.$inferInsert,
) {
	return executor.insert(idempotencyKeys).values(input);
}
export function deleteExpiredIdempotencyKeys(
	executor: DbExecutor,
	cutoff: Date,
) {
	return executor
		.delete(idempotencyKeys)
		.where(lt(idempotencyKeys.createdAt, cutoff));
}
