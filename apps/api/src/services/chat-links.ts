import {
	ChatIdentitiesResponse,
	ChatLinksResponse,
	type ChatPlatform,
	CreateChatLinkCodeResponse,
} from "@songphang/contract";
import {
	cancelUnconsumedPairingsForUser,
	consumeGroupLinkCode,
	deleteGroupChatLink,
	deleteUserChatIdentity,
	findGroup,
	insertChatLinkCode,
	listGroupChatLinks,
	listUserChatIdentities,
	upsertChatLink,
} from "@songphang/db";
import { uuidv7 } from "uuidv7";
import type { AppDeps } from "../app.js";
import {
	generateLinkCode,
	hashLinkCode,
	LINK_CODE_TTL_MS,
} from "../bot/link-codes.js";
import { AppError } from "../errors.js";

function requireTelegramEnabled(deps: AppDeps): void {
	if (deps.config.telegramProvider === null) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
}

export async function createGroupChatLinkCode(
	deps: AppDeps,
	input: { groupId: string; userId: string },
): Promise<CreateChatLinkCodeResponse> {
	requireTelegramEnabled(deps);
	const now = deps.now();
	const expiresAt = new Date(now.getTime() + LINK_CODE_TTL_MS);
	const code = generateLinkCode();
	await insertChatLinkCode(deps.db, {
		codeHash: hashLinkCode(code),
		purpose: "group",
		groupId: input.groupId,
		platform: "telegram",
		platformUserId: null,
		createdBy: input.userId,
		expiresAt,
		usedAt: null,
	});
	return CreateChatLinkCodeResponse.parse({
		command: `/lienket ${code}`,
		botUsername: deps.config.telegramBotUsername ?? null,
		expiresAt: expiresAt.toISOString(),
	});
}

export async function getGroupChatLinks(
	deps: AppDeps,
	groupId: string,
): Promise<ChatLinksResponse> {
	const rows = await listGroupChatLinks(deps.db, groupId);
	return ChatLinksResponse.parse({
		botUsername: deps.config.telegramBotUsername ?? null,
		chatLinks: rows.map((row) => ({
			id: row.id,
			platform: "telegram",
			chatId: row.chatId,
			linkedAt: row.createdAt.toISOString(),
		})),
	});
}

export async function unlinkGroupChat(
	deps: AppDeps,
	input: { groupId: string; chatLinkId: string },
): Promise<void> {
	const deleted = await deleteGroupChatLink(deps.db, input);
	if (!deleted) {
		throw new AppError(404, "NOT_FOUND", "Chat link not found");
	}
}

export async function getUserChatIdentities(
	deps: AppDeps,
	userId: string,
): Promise<ChatIdentitiesResponse> {
	const rows = await listUserChatIdentities(deps.db, userId);
	return ChatIdentitiesResponse.parse({
		chatIdentities: rows.map((row) => ({
			platform: "telegram",
			linkedAt: row.createdAt.toISOString(),
		})),
	});
}

export async function claimUserChatIdentity(
	deps: AppDeps,
	_input: { userId: string; code: string },
): Promise<void> {
	requireTelegramEnabled(deps);
	// Legacy public bearer claim codes are permanently disabled (R1 security fix).
	throw new AppError(400, "TOKEN_INVALID", "Invalid or expired link code");
}

export async function unlinkUserChatIdentity(
	deps: AppDeps,
	input: { userId: string; platform: ChatPlatform },
): Promise<void> {
	const now = deps.now();
	await deps.db.transaction(async (tx) => {
		await deleteUserChatIdentity(tx, input);
		await cancelUnconsumedPairingsForUser(tx, {
			userId: input.userId,
			platform: input.platform,
			now,
		});
	});
}

export async function redeemGroupChatLinkCode(
	deps: AppDeps,
	input: { chatId: string; rawCode: string },
): Promise<{ ok: true; groupName: string } | { ok: false }> {
	const trimmed = input.rawCode.trim();
	if (!trimmed) return { ok: false };
	const now = deps.now();
	return deps.db.transaction(async (tx) => {
		const consumed = await consumeGroupLinkCode(tx, {
			codeHash: hashLinkCode(trimmed),
			platform: "telegram",
			now,
		});
		if (!consumed?.groupId) return { ok: false };
		const group = await findGroup(tx, consumed.groupId);
		if (!group) return { ok: false };
		await upsertChatLink(tx, {
			id: uuidv7(),
			groupId: group.id,
			platform: "telegram",
			chatId: input.chatId,
			linkedBy: consumed.createdBy,
			now,
		});
		return { ok: true, groupName: group.name };
	});
}
