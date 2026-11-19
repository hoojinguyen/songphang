import { and, eq, gt, inArray, isNull, ne, or, sql } from "drizzle-orm";
import type { ChatPlatform } from "./chat.js";
import type { DbExecutor } from "./client.js";
import { sessions } from "./schema.js";
import { chatIdentityPairings } from "./schema-chat.js";

export async function findActiveSessionByHash(
	executor: DbExecutor,
	input: { userId: string; tokenHash: string; now: Date },
) {
	const [row] = await executor
		.select({
			id: sessions.id,
			userId: sessions.userId,
			expiresAt: sessions.expiresAt,
		})
		.from(sessions)
		.where(
			and(
				eq(sessions.userId, input.userId),
				eq(sessions.tokenHash, input.tokenHash),
				gt(sessions.expiresAt, input.now),
			),
		)
		.limit(1);
	return row ?? null;
}

export async function findActiveSessionById(
	executor: DbExecutor,
	input: { sessionId: string; now: Date },
) {
	const [row] = await executor
		.select({ id: sessions.id, userId: sessions.userId })
		.from(sessions)
		.where(
			and(eq(sessions.id, input.sessionId), gt(sessions.expiresAt, input.now)),
		)
		.limit(1);
	return row ?? null;
}

export async function insertChatIdentityPairing(
	executor: DbExecutor,
	input: typeof chatIdentityPairings.$inferInsert,
): Promise<void> {
	await executor.insert(chatIdentityPairings).values(input);
}

export async function cancelPairingBySecretHash(
	executor: DbExecutor,
	input: { secretHash: string; platform: ChatPlatform; now: Date },
): Promise<boolean> {
	const rows = await executor
		.update(chatIdentityPairings)
		.set({ status: "cancelled", consumedAt: input.now })
		.where(
			and(
				eq(chatIdentityPairings.secretHash, input.secretHash),
				eq(chatIdentityPairings.platform, input.platform),
				inArray(chatIdentityPairings.status, [
					"pending_telegram",
					"telegram_confirmed",
				]),
				isNull(chatIdentityPairings.consumedAt),
			),
		)
		.returning({ id: chatIdentityPairings.id });
	return rows.length > 0;
}

export async function findPairingBySecretHashForUpdate(
	executor: DbExecutor,
	input: { secretHash: string; platform: ChatPlatform },
) {
	const [row] = await executor
		.select()
		.from(chatIdentityPairings)
		.where(
			and(
				eq(chatIdentityPairings.secretHash, input.secretHash),
				eq(chatIdentityPairings.platform, input.platform),
			),
		)
		.for("update")
		.limit(1);
	return row ?? null;
}

export async function findPairingByIdForUpdate(
	executor: DbExecutor,
	pairingId: string,
) {
	const [row] = await executor
		.select()
		.from(chatIdentityPairings)
		.where(eq(chatIdentityPairings.id, pairingId))
		.for("update")
		.limit(1);
	return row ?? null;
}

export async function stageTelegramPairing(
	executor: DbExecutor,
	input: {
		pairingId: string;
		platformUserId: string;
		platformUserName: string | null;
		now: Date;
	},
): Promise<boolean> {
	const rows = await executor
		.update(chatIdentityPairings)
		.set({
			platformUserId: input.platformUserId,
			platformUserName: input.platformUserName,
		})
		.where(
			and(
				eq(chatIdentityPairings.id, input.pairingId),
				eq(chatIdentityPairings.status, "pending_telegram"),
				isNull(chatIdentityPairings.platformUserId),
				isNull(chatIdentityPairings.consumedAt),
				gt(chatIdentityPairings.expiresAt, input.now),
			),
		)
		.returning({ id: chatIdentityPairings.id });
	return rows.length > 0;
}

export async function confirmTelegramPairingOnBot(
	executor: DbExecutor,
	input: { pairingId: string; platformUserId: string; now: Date },
): Promise<boolean> {
	const rows = await executor
		.update(chatIdentityPairings)
		.set({ status: "telegram_confirmed", telegramConfirmedAt: input.now })
		.where(
			and(
				eq(chatIdentityPairings.id, input.pairingId),
				eq(chatIdentityPairings.status, "pending_telegram"),
				eq(chatIdentityPairings.platformUserId, input.platformUserId),
				isNull(chatIdentityPairings.consumedAt),
				gt(chatIdentityPairings.expiresAt, input.now),
			),
		)
		.returning({ id: chatIdentityPairings.id });
	return rows.length > 0;
}

export async function cancelTelegramPairing(
	executor: DbExecutor,
	input: { pairingId: string; now: Date },
): Promise<boolean> {
	const rows = await executor
		.update(chatIdentityPairings)
		.set({ status: "cancelled", consumedAt: input.now })
		.where(
			and(
				eq(chatIdentityPairings.id, input.pairingId),
				inArray(chatIdentityPairings.status, [
					"pending_telegram",
					"telegram_confirmed",
				]),
				isNull(chatIdentityPairings.consumedAt),
			),
		)
		.returning({ id: chatIdentityPairings.id });
	return rows.length > 0;
}

export async function findPairingForInitiatingSession(
	executor: DbExecutor,
	input: {
		pairingId: string;
		userId: string;
		sessionTokenHash: string;
		now: Date;
	},
) {
	const [row] = await executor
		.select({
			id: chatIdentityPairings.id,
			platform: chatIdentityPairings.platform,
			userId: chatIdentityPairings.userId,
			sessionId: chatIdentityPairings.sessionId,
			status: chatIdentityPairings.status,
			platformUserId: chatIdentityPairings.platformUserId,
			platformUserName: chatIdentityPairings.platformUserName,
			telegramConfirmedAt: chatIdentityPairings.telegramConfirmedAt,
			expiresAt: chatIdentityPairings.expiresAt,
			consumedAt: chatIdentityPairings.consumedAt,
			createdAt: chatIdentityPairings.createdAt,
		})
		.from(chatIdentityPairings)
		.innerJoin(sessions, eq(sessions.id, chatIdentityPairings.sessionId))
		.where(
			and(
				eq(chatIdentityPairings.id, input.pairingId),
				eq(chatIdentityPairings.userId, input.userId),
				eq(sessions.userId, input.userId),
				eq(sessions.tokenHash, input.sessionTokenHash),
				gt(sessions.expiresAt, input.now),
			),
		)
		.limit(1);
	return row ?? null;
}

export async function lockChatIdentityPlatformUser(
	executor: DbExecutor,
	input: { platform: ChatPlatform; platformUserId: string },
) {
	await executor.execute(
		sql`select pg_advisory_xact_lock(hashtextextended(${`chat_identity:${input.platform}:${input.platformUserId}`}, 0))`,
	);
}

export async function completeTelegramPairing(
	executor: DbExecutor,
	input: {
		pairingId: string;
		userId: string;
		platformUserId: string;
		now: Date;
	},
): Promise<boolean> {
	const rows = await executor
		.update(chatIdentityPairings)
		.set({ status: "completed", consumedAt: input.now })
		.where(
			and(
				eq(chatIdentityPairings.id, input.pairingId),
				eq(chatIdentityPairings.userId, input.userId),
				eq(chatIdentityPairings.status, "telegram_confirmed"),
				eq(chatIdentityPairings.platformUserId, input.platformUserId),
				isNull(chatIdentityPairings.consumedAt),
				gt(chatIdentityPairings.expiresAt, input.now),
			),
		)
		.returning({ id: chatIdentityPairings.id });
	if (rows.length === 0) return false;
	await executor
		.update(chatIdentityPairings)
		.set({ status: "cancelled", consumedAt: input.now })
		.where(
			and(
				ne(chatIdentityPairings.id, input.pairingId),
				isNull(chatIdentityPairings.consumedAt),
				inArray(chatIdentityPairings.status, [
					"pending_telegram",
					"telegram_confirmed",
				]),
				or(
					eq(chatIdentityPairings.userId, input.userId),
					eq(chatIdentityPairings.platformUserId, input.platformUserId),
				),
			),
		);
	return true;
}

export async function cancelUnconsumedPairingsForUser(
	executor: DbExecutor,
	input: { userId: string; platform: ChatPlatform; now: Date },
): Promise<void> {
	await executor
		.update(chatIdentityPairings)
		.set({ status: "cancelled", consumedAt: input.now })
		.where(
			and(
				eq(chatIdentityPairings.userId, input.userId),
				eq(chatIdentityPairings.platform, input.platform),
				isNull(chatIdentityPairings.consumedAt),
				inArray(chatIdentityPairings.status, [
					"pending_telegram",
					"telegram_confirmed",
				]),
			),
		);
}
