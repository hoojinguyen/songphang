import { and, eq } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { userIdentities } from "./schema-accounts.js";
export async function findGoogleIdentity(
	executor: DbExecutor,
	subject: string,
) {
	const [identity] = await executor
		.select({ userId: userIdentities.userId })
		.from(userIdentities)
		.where(
			and(
				eq(userIdentities.provider, "google"),
				eq(userIdentities.providerSubject, subject),
			),
		)
		.limit(1);
	return identity ?? null;
}
export function insertGoogleIdentity(
	executor: DbExecutor,
	input: { userId: string; subject: string; now: Date },
) {
	return executor
		.insert(userIdentities)
		.values({
			userId: input.userId,
			provider: "google",
			providerSubject: input.subject,
			createdAt: input.now,
		})
		.onConflictDoNothing();
}
