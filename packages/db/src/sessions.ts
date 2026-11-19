import { and, desc, eq, gt, ne } from "drizzle-orm";
import type { Db, DbExecutor } from "./client.js";
import { sessions, users } from "./schema.js";
import { USER_COLUMNS } from "./users.js";

export type DbSessionClient = "web" | "ios" | "android";

export async function insertSession(
	db: DbExecutor,
	input: {
		userId: string;
		tokenHash: string;
		expiresAt: Date;
		now: Date;
		userAgent?: string;
		client?: DbSessionClient;
		deviceName?: string;
	},
): Promise<{ id: string }> {
	const [inserted] = await db
		.insert(sessions)
		.values({
			userId: input.userId,
			tokenHash: input.tokenHash,
			expiresAt: input.expiresAt,
			createdAt: input.now,
			lastSeenAt: input.now,
			client: input.client ?? "web",
			...(input.deviceName === undefined
				? {}
				: { deviceName: input.deviceName }),
			...(input.userAgent === undefined ? {} : { userAgent: input.userAgent }),
		})
		.returning({ id: sessions.id });
	if (inserted === undefined) {
		throw new Error("Failed to insert session");
	}
	return inserted;
}

export async function listUserSessions(
	db: Db,
	input: { userId: string; now: Date },
) {
	return db
		.select({
			id: sessions.id,
			client: sessions.client,
			deviceName: sessions.deviceName,
			createdAt: sessions.createdAt,
			lastSeenAt: sessions.lastSeenAt,
			tokenHash: sessions.tokenHash,
		})
		.from(sessions)
		.where(
			and(eq(sessions.userId, input.userId), gt(sessions.expiresAt, input.now)),
		)
		.orderBy(desc(sessions.lastSeenAt), desc(sessions.createdAt));
}

export async function deleteUserSessionById(
	db: Db,
	input: { userId: string; sessionId: string },
): Promise<{ id: string; tokenHash: string } | null> {
	const [deleted] = await db
		.delete(sessions)
		.where(
			and(eq(sessions.id, input.sessionId), eq(sessions.userId, input.userId)),
		)
		.returning({ id: sessions.id, tokenHash: sessions.tokenHash });
	return deleted ?? null;
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
