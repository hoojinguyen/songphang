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
	lockGroup,
	upsertChatLink,
} from "@songphang/db";
import { uuidv7 } from "uuidv7";
import type { AppDeps } from "../app.js";
import { getGroupAccess } from "../auth/group-access.js";
import {
	generateLinkCode,
	hashLinkCode,
	LINK_CODE_TTL_MS,
} from "../bot/link-codes.js";
import { AppError } from "../errors.js";
import { assertGroupRowNotArchived } from "./group-guards.js";

class ArchivedGroupLinkError extends Error {}

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
	await deps.db.transaction(async (tx) => {
		const group = await lockGroup(tx, input.groupId);
		await getGroupAccess(tx, {
			groupId: input.groupId,
			userId: input.userId,
			minimumRole: "owner",
		});
		assertGroupRowNotArchived(group);
		await insertChatLinkCode(tx, {
			codeHash: hashLinkCode(code),
			purpose: "group",
			groupId: input.groupId,
			platform: "telegram",
			platformUserId: null,
			createdBy: input.userId,
			expiresAt,
			usedAt: null,
		});
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
	input: { groupId: string; userId: string; chatLinkId: string },
): Promise<void> {
	const deleted = await deps.db.transaction(async (tx) => {
		const group = await lockGroup(tx, input.groupId);
		await getGroupAccess(tx, {
			groupId: input.groupId,
			userId: input.userId,
			minimumRole: "owner",
		});
		assertGroupRowNotArchived(group);
		return deleteGroupChatLink(tx, {
			groupId: input.groupId,
			chatLinkId: input.chatLinkId,
		});
	});
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
): Promise<
	{ ok: true; groupName: string } | { ok: false; archived?: boolean }
> {
	const trimmed = input.rawCode.trim();
	if (!trimmed) return { ok: false };
	const now = deps.now();
	try {
		return await deps.db.transaction(async (tx) => {
			const consumed = await consumeGroupLinkCode(tx, {
				codeHash: hashLinkCode(trimmed),
				platform: "telegram",
				now,
			});
			if (!consumed?.groupId) return { ok: false };
			const locked = await lockGroup(tx, consumed.groupId);
			if (!locked) return { ok: false };
			if (locked.archivedAt !== null) {
				throw new ArchivedGroupLinkError();
			}
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
	} catch (error) {
		if (error instanceof ArchivedGroupLinkError) {
			return { ok: false, archived: true };
		}
		throw error;
	}
}
