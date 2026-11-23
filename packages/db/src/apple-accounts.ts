import { and, eq, ne, or, sql } from "drizzle-orm";
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
					email === undefined ? undefined : eq(appleOperations.email, email),
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
		.values(operation)
		.onConflictDoUpdate({
			target: appleOperations.key,
			set: {
				owner: operation.owner,
				userId: operation.userId ?? null,
				email: operation.email ?? null,
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
