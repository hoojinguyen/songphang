import { and, eq, gt, ne } from "drizzle-orm";
import type { Db, DbExecutor } from "./client.js";
import { sessions, users } from "./schema.js";
import { USER_COLUMNS } from "./users.js";

export async function insertSession(
	db: Db,
	input: {
		userId: string;
		tokenHash: string;
		expiresAt: Date;
		now: Date;
		userAgent?: string;
	},
): Promise<void> {
	await db.insert(sessions).values({
		userId: input.userId,
		tokenHash: input.tokenHash,
		expiresAt: input.expiresAt,
		createdAt: input.now,
		lastSeenAt: input.now,
		...(input.userAgent === undefined ? {} : { userAgent: input.userAgent }),
	});
}

export async function findUserBySessionHash(
	db: Db,
	input: { tokenHash: string; now: Date },
) {
	const [user] = await db
		.select(USER_COLUMNS)
		.from(sessions)
		.innerJoin(users, eq(sessions.userId, users.id))
		.where(
			and(
				eq(sessions.tokenHash, input.tokenHash),
				gt(sessions.expiresAt, input.now),
			),
		)
		.limit(1);
	return user ?? null;
}

export async function deleteSessionByHash(
	db: Db,
	tokenHash: string,
): Promise<void> {
	await db.delete(sessions).where(eq(sessions.tokenHash, tokenHash));
}

export function deleteUserSessions(
	executor: DbExecutor,
	input: { userId: string; keepTokenHash?: string },
) {
	return executor
		.delete(sessions)
		.where(
			and(
				eq(sessions.userId, input.userId),
				input.keepTokenHash === undefined
					? undefined
					: ne(sessions.tokenHash, input.keepTokenHash),
			),
		);
}
