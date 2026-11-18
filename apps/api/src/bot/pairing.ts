import {
	cancelPairingBySecretHash,
	cancelTelegramPairing,
	confirmTelegramPairingOnBot,
	findActiveSessionById,
	findChatIdentity,
	findPairingByIdForUpdate,
	findPairingBySecretHashForUpdate,
	findUserById,
	stageTelegramPairing,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { BOT_MESSAGES, maskEmail } from "../bot-messages.js";
import type { ChatSender } from "./chat-sender.js";
import { hashPairingSecret, isValidPairingSecretFormat } from "./link-codes.js";
import type { TelegramUpdate } from "./telegram-update.js";

const PAIRING_CALLBACK_PATTERN = /^(pc|px):([0-9a-f-]{36})$/i;

type StartOutcome =
	| { kind: "invalid" }
	| { kind: "taken" }
	| {
			kind: "staged";
			pairingId: string;
			userName: string;
			maskedEmail: string;
	  };

type CallbackOutcome =
	| { kind: "ignore" }
	| { kind: "already_confirmed" }
	| { kind: "invalid" }
	| { kind: "taken" }
	| { kind: "cancelled" }
	| { kind: "confirmed" };

export async function handleTelegramPairingStartCommand(
	deps: AppDeps,
	sender: ChatSender,
	input: {
		chatId: string;
		chatType: string;
		platformUserId: string;
		platformUserName: string | null;
		rawSecret: string;
	},
): Promise<void> {
	const now = deps.now();
	if (input.chatType !== "private") {
		if (isValidPairingSecretFormat(input.rawSecret)) {
			await cancelPairingBySecretHash(deps.db, {
				secretHash: hashPairingSecret(input.rawSecret),
				platform: "telegram",
				now,
			});
		}
		await sender.send(input.chatId, BOT_MESSAGES.pairingPrivateOnly);
		return;
	}
	if (
		input.chatId !== input.platformUserId ||
		!isValidPairingSecretFormat(input.rawSecret)
	) {
		await sender.send(input.chatId, BOT_MESSAGES.pairingInvalidOrExpired);
		return;
	}
	const secretHash = hashPairingSecret(input.rawSecret);
	const outcome: StartOutcome = await deps.db.transaction(async (tx) => {
		const pairing = await findPairingBySecretHashForUpdate(tx, {
			secretHash,
			platform: "telegram",
		});
		if (
			!pairing ||
			pairing.consumedAt !== null ||
			pairing.status !== "pending_telegram" ||
			pairing.platformUserId !== null ||
			pairing.expiresAt.getTime() <= now.getTime()
		) {
			return { kind: "invalid" };
		}
		const [user, activeSession, existingIdentity] = await Promise.all([
			findUserById(tx, pairing.userId),
			findActiveSessionById(tx, { sessionId: pairing.sessionId, now }),
			findChatIdentity(tx, {
				platform: "telegram",
				platformUserId: input.platformUserId,
			}),
		]);
		if (!user?.emailVerified || !activeSession) {
			return { kind: "invalid" };
		}
		if (existingIdentity && existingIdentity.userId !== pairing.userId) {
			return { kind: "taken" };
		}
		const staged = await stageTelegramPairing(tx, {
			pairingId: pairing.id,
			platformUserId: input.platformUserId,
			platformUserName: input.platformUserName,
			now,
		});
		if (!staged) return { kind: "invalid" };
		return {
			kind: "staged",
			pairingId: pairing.id,
			userName: user.name,
			maskedEmail: maskEmail(user.email),
		};
	});

	if (outcome.kind === "taken") {
		await sender.send(input.chatId, BOT_MESSAGES.pairingIdentityTaken);
		return;
	}
	if (outcome.kind === "invalid") {
		await sender.send(input.chatId, BOT_MESSAGES.pairingInvalidOrExpired);
		return;
	}
	await sender.send(
		input.chatId,
		BOT_MESSAGES.pairingPrompt(outcome.userName, outcome.maskedEmail),
		[
			{
				text: BOT_MESSAGES.pairingConfirmButton,
				data: `pc:${outcome.pairingId}`,
			},
			{
				text: BOT_MESSAGES.pairingCancelButton,
				data: `px:${outcome.pairingId}`,
			},
		],
	);
}

export async function handleTelegramPairingCallback(
	deps: AppDeps,
	sender: ChatSender,
	cb: NonNullable<TelegramUpdate["callback_query"]>,
): Promise<boolean> {
	const match = cb.data?.match(PAIRING_CALLBACK_PATTERN);
	if (!match?.[1] || !match[2]) return false;

	const chatId = cb.message?.chat.id;
	if (!chatId || cb.message?.chat.type !== "private" || chatId !== cb.from.id) {
		await sender.answerCallback(cb.id);
		return true;
	}

	const action = match[1].toLowerCase();
	const pairingId = match[2].toLowerCase();
	const now = deps.now();

	const outcome: CallbackOutcome = await deps.db.transaction(async (tx) => {
		const pairing = await findPairingByIdForUpdate(tx, pairingId);
		if (
			!pairing ||
			pairing.platformUserId === null ||
			pairing.platformUserId !== cb.from.id
		) {
			return { kind: "ignore" };
		}
		if (action === "px") {
			if (pairing.status === "cancelled") return { kind: "ignore" };
			if (
				pairing.status === "completed" ||
				pairing.consumedAt !== null ||
				pairing.expiresAt.getTime() <= now.getTime()
			) {
				return { kind: "invalid" };
			}
			await cancelTelegramPairing(tx, { pairingId: pairing.id, now });
			return { kind: "cancelled" };
		}
		if (
			pairing.status === "telegram_confirmed" &&
			pairing.consumedAt === null &&
			pairing.expiresAt.getTime() > now.getTime()
		) {
			return { kind: "already_confirmed" };
		}
		if (
			pairing.status !== "pending_telegram" ||
			pairing.consumedAt !== null ||
			pairing.expiresAt.getTime() <= now.getTime()
		) {
			return { kind: "invalid" };
		}
		const [user, activeSession, existingIdentity] = await Promise.all([
			findUserById(tx, pairing.userId),
			findActiveSessionById(tx, { sessionId: pairing.sessionId, now }),
			findChatIdentity(tx, {
				platform: "telegram",
				platformUserId: cb.from.id,
			}),
		]);
		if (!user?.emailVerified || !activeSession) {
			return { kind: "invalid" };
		}
		if (existingIdentity && existingIdentity.userId !== pairing.userId) {
			return { kind: "taken" };
		}
		const confirmed = await confirmTelegramPairingOnBot(tx, {
			pairingId: pairing.id,
			platformUserId: cb.from.id,
			now,
		});
		return confirmed ? { kind: "confirmed" } : { kind: "invalid" };
	});

	await sender.answerCallback(cb.id);
	switch (outcome.kind) {
		case "confirmed":
			await sender.send(chatId, BOT_MESSAGES.pairingTelegramConfirmed);
			return true;
		case "cancelled":
			await sender.send(chatId, BOT_MESSAGES.pairingCancelled);
			return true;
		case "taken":
			await sender.send(chatId, BOT_MESSAGES.pairingIdentityTaken);
			return true;
		case "invalid":
			await sender.send(chatId, BOT_MESSAGES.pairingInvalidOrExpired);
			return true;
		case "ignore":
		case "already_confirmed":
			return true;
	}
}
