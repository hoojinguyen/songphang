import { and, count, eq, gt, isNull, sql } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { users } from "./schema.js";
import { authTokens, userIdentities } from "./schema-accounts.js";
import { groupUsers } from "./schema-groups.js";
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
export async function consumeMobileExchangeToken(
	executor: DbExecutor,
	input: {
		tokenHash: string;
		codeChallenge: string;
		client: "ios" | "android";
		now: Date;
	},
) {
	const [token] = await executor
		.update(authTokens)
		.set({ usedAt: input.now })
		.where(
			and(
				eq(authTokens.tokenHash, input.tokenHash),
				eq(authTokens.purpose, "mobile_exchange"),
				eq(authTokens.codeChallenge, input.codeChallenge),
				eq(authTokens.client, input.client),
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
		.onConflictDoNothing()
		.returning({ id: users.id });
	return account ?? null;
}

export function verifyAccountEmail(
	executor: DbExecutor,
	input: { userId: string; now: Date },
) {
	return executor
		.update(users)
		.set({
			emailVerifiedAt: sql`coalesce(${users.emailVerifiedAt}, ${input.now.toISOString()}::timestamptz)`,
			updatedAt: input.now,
		})
		.where(eq(users.id, input.userId));
}

export async function findAccountById(executor: DbExecutor, userId: string) {
	const [account] = await executor
		.select({
			id: users.id,
			email: users.email,
			name: users.name,
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
		.where(eq(users.id, userId))
		.limit(1);
	return account ?? null;
}
export function updatePasswordHash(
	executor: DbExecutor,
	input: { userId: string; passwordHash: string },
) {
	return executor
		.update(userIdentities)
		.set({ passwordHash: input.passwordHash })
		.where(
			and(
				eq(userIdentities.userId, input.userId),
				eq(userIdentities.provider, "password"),
			),
		);
}
export async function countOwnedGroups(
	executor: DbExecutor,
	userId: string,
): Promise<number> {
	const [row] = await executor
		.select({ count: count() })
		.from(groupUsers)
		.where(and(eq(groupUsers.userId, userId), eq(groupUsers.role, "owner")));
	return row?.count ?? 0;
}
export function deleteAccountRow(executor: DbExecutor, userId: string) {
	return executor.delete(users).where(eq(users.id, userId));
}
export async function findAuthTokenUser(
	executor: DbExecutor,
	input: { tokenHash: string; purpose: TokenPurpose; now: Date },
) {
	const [row] = await executor
		.select({ userId: authTokens.userId })
		.from(authTokens)
		.where(
			and(
				eq(authTokens.tokenHash, input.tokenHash),
				eq(authTokens.purpose, input.purpose),
				isNull(authTokens.usedAt),
				gt(authTokens.expiresAt, input.now),
			),
		)
		.limit(1);
	return row?.userId ?? null;
}
