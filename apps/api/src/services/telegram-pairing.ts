import {
	StartTelegramPairingResponse,
	TelegramPairingDto,
	TelegramPairingResponse,
	TelegramPairingStatus,
} from "@songphang/contract";
import {
	cancelTelegramPairing,
	completeTelegramPairing,
	findActiveSessionByHash,
	findChatIdentity,
	findPairingByIdForUpdate,
	findPairingForInitiatingSession,
	findUserById,
	insertChatIdentityPairing,
	lockChatIdentityPlatformUser,
	upsertUserChatIdentity,
} from "@songphang/db";
import { uuidv7 } from "uuidv7";
import type { AppDeps } from "../app.js";
import { hashSessionToken } from "../auth/sessions.js";
import {
	generatePairingSecret,
	hashPairingSecret,
	LINK_CODE_TTL_MS,
} from "../bot/link-codes.js";
import { AppError } from "../errors.js";

function requireTelegramEnabled(deps: AppDeps): void {
	if (deps.config.telegramProvider === null) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
}

function toPairingDto(
	row: {
		id: string;
		status: string;
		platformUserId: string | null;
		platformUserName: string | null;
		expiresAt: Date;
	},
	botUsername: string | null,
	now: Date,
): TelegramPairingDto {
	const isExpired =
		(row.status === "pending_telegram" ||
			row.status === "telegram_confirmed") &&
		row.expiresAt.getTime() <= now.getTime();
	const effectiveStatus = TelegramPairingStatus.parse(
		isExpired ? "expired" : row.status,
	);
	return TelegramPairingDto.parse({
		id: row.id,
		status: effectiveStatus,
		botUsername,
		stagedPlatformUserId: row.platformUserId,
		stagedPlatformName: row.platformUserName,
		expiresAt: row.expiresAt.toISOString(),
	});
}

export async function startTelegramPairingAttempt(
	deps: AppDeps,
	input: { userId: string; sessionToken: string },
): Promise<StartTelegramPairingResponse> {
	requireTelegramEnabled(deps);
	const now = deps.now();
	const session = await findActiveSessionByHash(deps.db, {
		userId: input.userId,
		tokenHash: hashSessionToken(input.sessionToken),
		now,
	});
	if (!session) {
		throw new AppError(401, "UNAUTHENTICATED", "Authentication required");
	}
	const secret = generatePairingSecret();
	const id = uuidv7();
	const expiresAt = new Date(now.getTime() + LINK_CODE_TTL_MS);
	await insertChatIdentityPairing(deps.db, {
		id,
		platform: "telegram",
		userId: input.userId,
		sessionId: session.id,
		secretHash: hashPairingSecret(secret),
		status: "pending_telegram",
		platformUserId: null,
		platformUserName: null,
		telegramConfirmedAt: null,
		expiresAt,
		consumedAt: null,
		createdAt: now,
	});
	const botUsername = deps.config.telegramBotUsername ?? null;
	const deepLinkUrl = botUsername
		? `https://t.me/${botUsername}?start=${encodeURIComponent(secret)}`
		: null;
	return StartTelegramPairingResponse.parse({
		pairing: toPairingDto(
			{
				id,
				status: "pending_telegram",
				platformUserId: null,
				platformUserName: null,
				expiresAt,
			},
			botUsername,
			now,
		),
		startCommand: `/start ${secret}`,
		deepLinkUrl,
	});
}

export async function getTelegramPairingAttempt(
	deps: AppDeps,
	input: { pairingId: string; userId: string; sessionToken: string },
): Promise<TelegramPairingResponse> {
	requireTelegramEnabled(deps);
	const now = deps.now();
	const row = await findPairingForInitiatingSession(deps.db, {
		pairingId: input.pairingId,
		userId: input.userId,
		sessionTokenHash: hashSessionToken(input.sessionToken),
		now,
	});
	if (!row) {
		throw new AppError(404, "NOT_FOUND", "Pairing attempt not found");
	}
	return TelegramPairingResponse.parse({
		pairing: toPairingDto(row, deps.config.telegramBotUsername ?? null, now),
	});
}

export async function cancelTelegramPairingFromWeb(
	deps: AppDeps,
	input: { pairingId: string; userId: string; sessionToken: string },
): Promise<void> {
	requireTelegramEnabled(deps);
	const now = deps.now();
	await deps.db.transaction(async (tx) => {
		const row = await findPairingForInitiatingSession(tx, {
			pairingId: input.pairingId,
			userId: input.userId,
			sessionTokenHash: hashSessionToken(input.sessionToken),
			now,
		});
		if (!row) {
			throw new AppError(404, "NOT_FOUND", "Pairing attempt not found");
		}
		await findPairingByIdForUpdate(tx, row.id);
		await cancelTelegramPairing(tx, { pairingId: row.id, now });
	});
}

export async function confirmTelegramPairingFromWeb(
	deps: AppDeps,
	input: { pairingId: string; userId: string; sessionToken: string },
): Promise<void> {
	requireTelegramEnabled(deps);
	const now = deps.now();
	await deps.db.transaction(async (tx) => {
		const pairing = await findPairingByIdForUpdate(tx, input.pairingId);
		if (!pairing || pairing.userId !== input.userId) {
			throw new AppError(404, "NOT_FOUND", "Pairing attempt not found");
		}
		const session = await findActiveSessionByHash(tx, {
			userId: input.userId,
			tokenHash: hashSessionToken(input.sessionToken),
			now,
		});
		if (!session || session.id !== pairing.sessionId) {
			throw new AppError(404, "NOT_FOUND", "Pairing attempt not found");
		}
		const user = await findUserById(tx, input.userId);
		if (!user?.emailVerified) {
			throw new AppError(
				403,
				"EMAIL_NOT_VERIFIED",
				"Verified email is required",
			);
		}
		if (
			pairing.consumedAt !== null ||
			pairing.status !== "telegram_confirmed" ||
			pairing.platformUserId === null ||
			pairing.expiresAt.getTime() <= now.getTime()
		) {
			throw new AppError(
				400,
				"TOKEN_INVALID",
				"Pairing confirmation is invalid or expired",
			);
		}
		await lockChatIdentityPlatformUser(tx, {
			platform: "telegram",
			platformUserId: pairing.platformUserId,
		});
		const existing = await findChatIdentity(tx, {
			platform: "telegram",
			platformUserId: pairing.platformUserId,
		});
		if (existing && existing.userId !== input.userId) {
			throw new AppError(
				409,
				"CHAT_IDENTITY_TAKEN",
				"Telegram account is already linked to another user",
			);
		}
		const completed = await completeTelegramPairing(tx, {
			pairingId: pairing.id,
			userId: input.userId,
			platformUserId: pairing.platformUserId,
			now,
		});
		if (!completed) {
			throw new AppError(
				400,
				"TOKEN_INVALID",
				"Pairing confirmation is invalid or expired",
			);
		}
		await upsertUserChatIdentity(tx, {
			platform: "telegram",
			platformUserId: pairing.platformUserId,
			userId: input.userId,
			now,
		});
	});
}
