import { and, eq } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { userIdentities } from "./schema-accounts.js";

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
	input: { userId: string; subject: string; providerSecret: string },
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
