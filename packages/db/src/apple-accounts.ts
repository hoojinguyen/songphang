import { createHash, randomUUID } from "node:crypto";
import { and, eq, lt, ne, or, sql } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { appleOperations, userIdentities } from "./schema-accounts.js";

export async function findAppleIdentity(executor: DbExecutor, subject: string) {
	const [identity] = await executor
		.select({
			userId: userIdentities.userId,
			providerSecret: userIdentities.providerSecret,
		})
		.from(userIdentities)
		.where(
			and(
				eq(userIdentities.provider, "apple"),
				eq(userIdentities.providerSubject, subject),
			),
		)
		.limit(1);
	return identity ?? null;
}

export async function findUserAppleIdentity(
	executor: DbExecutor,
	userId: string,
) {
	const [identity] = await executor
		.select({
			id: userIdentities.id,
			providerSubject: userIdentities.providerSubject,
			providerSecret: userIdentities.providerSecret,
		})
		.from(userIdentities)
		.where(
			and(
				eq(userIdentities.userId, userId),
				eq(userIdentities.provider, "apple"),
			),
		)
		.limit(1);
	return identity ?? null;
}

export function insertAppleIdentity(
	executor: DbExecutor,
	input: {
		userId: string;
		subject: string;
		providerSecret: string | null;
		now: Date;
	},
) {
	return executor
		.insert(userIdentities)
		.values({
			userId: input.userId,
			provider: "apple",
			providerSubject: input.subject,
			providerSecret: input.providerSecret,
			createdAt: input.now,
		})
		.onConflictDoNothing();
}

export function updateAppleProviderSecret(
	executor: DbExecutor,
	input: { userId: string; subject: string; providerSecret: string | null },
) {
	return executor
		.update(userIdentities)
		.set({ providerSecret: input.providerSecret })
		.where(
			and(
				eq(userIdentities.userId, input.userId),
				eq(userIdentities.provider, "apple"),
				eq(userIdentities.providerSubject, input.subject),
			),
		);
}

export function lockAppleOperation(executor: DbExecutor, key: string) {
	return executor.execute(
		sql`select pg_advisory_xact_lock(hashtextextended(${`apple:${key}`}, 0))`,
	);
}

export async function findAppleOperation(executor: DbExecutor, key: string) {
	const [operation] = await executor
		.select()
		.from(appleOperations)
		.where(eq(appleOperations.key, key));
	return operation ?? null;
}

export async function hasAppleExchange(
	executor: DbExecutor,
	userId: string | undefined,
	email: string | undefined,
	exceptKey?: string,
) {
	if (userId === undefined && email === undefined) return false;
	const [operation] = await executor
		.select({ key: appleOperations.key })
		.from(appleOperations)
		.where(
			and(
				sql`${appleOperations.key} like 'exchange:%'`,
				exceptKey === undefined
					? undefined
					: ne(appleOperations.key, exceptKey),
				or(
					userId === undefined ? undefined : eq(appleOperations.userId, userId),
					email === undefined
						? undefined
						: eq(appleOperations.email, email.toLowerCase()),
				),
			),
		)
		.limit(1);
	return operation !== undefined;
}

export function saveAppleOperation(
	executor: DbExecutor,
	operation: typeof appleOperations.$inferInsert,
) {
	return executor
		.insert(appleOperations)
		.values({ ...operation, email: operation.email?.toLowerCase() })
		.onConflictDoUpdate({
			target: appleOperations.key,
			set: {
				owner: operation.owner,
				userId: operation.userId ?? null,
				email: operation.email?.toLowerCase() ?? null,
				expiresAt: operation.expiresAt,
			},
		});
}

export function clearAppleOperation(
	executor: DbExecutor,
	key: string,
	owner: string,
) {
	return executor
		.delete(appleOperations)
		.where(and(eq(appleOperations.key, key), eq(appleOperations.owner, owner)));
}

export function finishAppleExchange(
	executor: DbExecutor,
	key: string,
	owner: string,
) {
	return executor
		.update(appleOperations)
		.set({
			key: `finished-exchange:${owner}`,
			userId: null,
			email: null,
			expiresAt: new Date(0),
		})
		.where(and(eq(appleOperations.key, key), eq(appleOperations.owner, owner)));
}

export function releaseAppleExchangeLease(
	executor: DbExecutor,
	key: string,
	owner: string,
) {
	return executor
		.update(appleOperations)
		.set({ expiresAt: new Date(0) })
		.where(and(eq(appleOperations.key, key), eq(appleOperations.owner, owner)));
}

function deletionKey(kind: "email" | "subject", value: string) {
	return `deleted:${kind}:${createHash("sha256").update(value).digest("hex")}`;
}

export async function hasRecentAppleDeletion(
	executor: DbExecutor,
	subject: string,
	email?: string,
) {
	const keys = [deletionKey("subject", subject)];
	if (email) keys.push(deletionKey("email", email.toLowerCase()));
	const now = new Date();
	for (const key of keys) {
		const marker = await findAppleOperation(executor, key);
		if (marker && marker.expiresAt > now) return true;
	}
	return false;
}

export async function recordAppleDeletion(
	executor: DbExecutor,
	email: string,
	subject?: string | null,
) {
	const keys = [deletionKey("email", email.toLowerCase())];
	if (subject) keys.push(deletionKey("subject", subject));
	// Outlast token verification and allow a fresh registration after the guard window.
	const expiresAt = new Date(Date.now() + 5 * 60_000);
	for (const key of keys) {
		await saveAppleOperation(executor, { key, owner: randomUUID(), expiresAt });
	}
}

export async function clearExpiredConflictingAppleExchanges(
	executor: DbExecutor,
	userId: string,
	email: string | undefined,
	subject: string,
) {
	// A different subject cannot be associated with this account once its Apple identity exists.
	await executor
		.delete(appleOperations)
		.where(
			and(
				sql`${appleOperations.key} like 'exchange:%'`,
				ne(appleOperations.key, `exchange:${subject}`),
				lt(appleOperations.expiresAt, new Date()),
				or(
					eq(appleOperations.userId, userId),
					email === undefined
						? undefined
						: eq(appleOperations.email, email.toLowerCase()),
				),
			),
		);
}

export function pruneExpiredAppleOperations(executor: DbExecutor) {
	// Uncertain exchanges retain their outcome independently of the exclusive lease.
	return executor.execute(sql`
		delete from apple_operations where key in (
			select key from apple_operations
			where expires_at < now() and (key like 'deleted:%' or key like 'revoke:%' or key like 'finished-exchange:%')
			order by expires_at limit 64 for update skip locked
		)
	`);
}
