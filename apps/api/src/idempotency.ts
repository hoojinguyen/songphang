import { createHash } from "node:crypto";
import { z } from "@hono/zod-openapi";
import {
	type DbExecutor,
	deleteExpiredIdempotencyKeys,
	findIdempotencyKey,
	insertIdempotencyKey,
} from "@songphang/db";
import type { AppDeps } from "./app.js";
import { AppError } from "./errors.js";

type IdempotentInput = {
	userId: string;
	key: string;
	requestHash: string;
	onCommitted?: (body: unknown) => void;
};
type Operation = (
	transaction: DbExecutor,
) => Promise<{ status: 200 | 201; body: unknown }>;
export function hashRequest(
	method: string,
	path: string,
	body: unknown,
): string {
	return createHash("sha256")
		.update(JSON.stringify([method, path, body]))
		.digest("hex");
}
function reuseStored(
	stored: { requestHash: string; status: number; body: unknown },
	requestHash: string,
) {
	if (stored.requestHash !== requestHash)
		throw new AppError(
			409,
			"IDEMPOTENCY_KEY_REUSED",
			"Idempotency key was used with another request",
		);
	return { status: stored.status, body: stored.body, replayed: true };
}
function isKeyConflict(error: unknown): boolean {
	const parsed = z
		.object({
			code: z.literal("23505"),
			constraint_name: z.literal("idempotency_keys_user_id_key_pk"),
		})
		.safeParse(error);
	if (parsed.success) return true;
	const wrapped = z.object({ cause: z.unknown() }).safeParse(error);
	return (
		wrapped.success &&
		wrapped.data.cause !== undefined &&
		isKeyConflict(wrapped.data.cause)
	);
}
export async function runIdempotent(
	deps: AppDeps,
	input: IdempotentInput,
	operation: Operation,
): Promise<{ status: number; body: unknown }> {
	const now = deps.now();
	const cutoff = new Date(now.getTime() - 24 * 60 * 60 * 1000);
	try {
		const result = await deps.db.transaction(async (transaction) => {
			await deleteExpiredIdempotencyKeys(transaction, cutoff);
			const stored = await findIdempotencyKey(
				transaction,
				input.userId,
				input.key,
			);
			if (stored !== null) return reuseStored(stored, input.requestHash);
			const response = await operation(transaction);
			await insertIdempotencyKey(transaction, {
				userId: input.userId,
				key: input.key,
				requestHash: input.requestHash,
				responseStatus: response.status,
				responseBody: response.body,
				createdAt: now,
			});
			return { ...response, replayed: false };
		});
		if (!result.replayed) input.onCommitted?.(result.body);
		return result;
	} catch (error) {
		if (!isKeyConflict(error)) throw error;
		const stored = await findIdempotencyKey(deps.db, input.userId, input.key);
		if (stored === null) throw error;
		return reuseStored(stored, input.requestHash);
	}
}
