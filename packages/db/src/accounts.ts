import { and, eq, gt, isNull, sql } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { users } from "./schema.js";
import { authTokens, userIdentities } from "./schema-accounts.js";
export type TokenPurpose = typeof authTokens.$inferInsert.purpose;
export function lockAccount(executor: DbExecutor, userId: string) {
	return executor
		.select({ id: users.id })
		.from(users)
		.where(eq(users.id, userId))
		.for("update");
}
export function invalidateAuthTokens(
	executor: DbExecutor,
	input: { userId: string; purpose: TokenPurpose; now: Date },
) {
	return executor
		.update(authTokens)
		.set({ usedAt: input.now })
		.where(
			and(
				eq(authTokens.userId, input.userId),
				eq(authTokens.purpose, input.purpose),
				isNull(authTokens.usedAt),
			),
		);
}
export function insertAuthToken(
	executor: DbExecutor,
	input: typeof authTokens.$inferInsert,
) {
	return executor.insert(authTokens).values(input);
}
export async function consumeAuthToken(
	executor: DbExecutor,
	input: { tokenHash: string; purpose: TokenPurpose; now: Date },
) {
	const [token] = await executor
		.update(authTokens)
		.set({ usedAt: input.now })
		.where(
			and(
				eq(authTokens.tokenHash, input.tokenHash),
				eq(authTokens.purpose, input.purpose),
				isNull(authTokens.usedAt),
				gt(authTokens.expiresAt, input.now),
			),
		)
		.returning({ userId: authTokens.userId });
	return token?.userId ?? null;
}
export async function findAccountByEmail(executor: DbExecutor, email: string) {
	const [account] = await executor
		.select({
			id: users.id,
			email: users.email,
			name: users.name,
			avatarUrl: users.avatarUrl,
			emailVerifiedAt: users.emailVerifiedAt,
			passwordHash: userIdentities.passwordHash,
		})
		.from(users)
		.leftJoin(
			userIdentities,
			and(
				eq(userIdentities.userId, users.id),
				eq(userIdentities.provider, "password"),
			),
		)
		.where(sql`lower(${users.email}) = ${email.toLowerCase()}`)
		.limit(1);
	return account ?? null;
}
export function insertIdentity(
	executor: DbExecutor,
	input: typeof userIdentities.$inferInsert,
) {
	return executor.insert(userIdentities).values(input);
}
export async function insertAccount(
	executor: DbExecutor,
	input: typeof users.$inferInsert,
) {
	const [account] = await executor
		.insert(users)
		.values(input)
		.returning({ id: users.id });
	if (!account) throw new Error("Account insert failed");
	return account;
}
