import { createHash, randomBytes } from "node:crypto";
import {
	consumeAuthToken,
	type DbExecutor,
	insertAuthToken,
	invalidateAuthTokens,
	lockAccount,
	type TokenPurpose,
} from "@songphang/db";
export async function issueToken(
	executor: DbExecutor,
	input: { userId: string; purpose: TokenPurpose; now: Date },
): Promise<string> {
	return executor.transaction(async (transaction) => {
		await lockAccount(transaction, input.userId);
		await invalidateAuthTokens(transaction, input);
		const token = randomBytes(32).toString("base64url");
		const tokenHash = createHash("sha256").update(token).digest("hex");
		const lifetimeMs =
			input.purpose === "verify_email" ? 24 * 60 * 60 * 1000 : 60 * 60 * 1000;
		await insertAuthToken(transaction, {
			userId: input.userId,
			purpose: input.purpose,
			tokenHash,
			expiresAt: new Date(input.now.getTime() + lifetimeMs),
			createdAt: input.now,
		});
		return token;
	});
}
export function consumeToken(
	executor: DbExecutor,
	input: { token: string; purpose: TokenPurpose; now: Date },
): Promise<string | null> {
	if (!/^[A-Za-z0-9_-]{43}$/.test(input.token)) return Promise.resolve(null);
	return consumeAuthToken(executor, {
		tokenHash: createHash("sha256").update(input.token).digest("hex"),
		purpose: input.purpose,
		now: input.now,
	});
}
