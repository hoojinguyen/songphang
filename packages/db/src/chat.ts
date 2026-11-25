import { and, asc, desc, eq, gt, isNotNull, isNull, lt, or } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import {
	botDrafts,
	botUpdates,
	chatIdentities,
	chatIdentityPairings,
	chatLinkCodes,
	chatLinks,
} from "./schema-chat.js";
import { groups } from "./schema-groups.js";

export type ChatPlatform = "telegram";

export async function recordBotUpdateIfNew(
	executor: DbExecutor,
	input: { platform: ChatPlatform; updateId: string; now: Date },
): Promise<boolean> {
	const rows = await executor
		.insert(botUpdates)
		.values({
			platform: input.platform,
			updateId: input.updateId,
			createdAt: input.now,
		})
		.onConflictDoNothing()
		.returning({ updateId: botUpdates.updateId });
	return rows.length > 0;
}

export async function insertChatLinkCode(
	executor: DbExecutor,
	input: typeof chatLinkCodes.$inferInsert,
): Promise<void> {
	await executor.insert(chatLinkCodes).values(input);
}

export async function consumeGroupLinkCode(
	executor: DbExecutor,
	input: { codeHash: string; platform: ChatPlatform; now: Date },
) {
	const [row] = await executor
		.update(chatLinkCodes)
		.set({ usedAt: input.now })
		.where(
			and(
				eq(chatLinkCodes.codeHash, input.codeHash),
				eq(chatLinkCodes.purpose, "group"),
				eq(chatLinkCodes.platform, input.platform),
				isNull(chatLinkCodes.usedAt),
				gt(chatLinkCodes.expiresAt, input.now),
			),
		)
		.returning({
			groupId: chatLinkCodes.groupId,
			createdBy: chatLinkCodes.createdBy,
		});
	return row ?? null;
}

export async function upsertChatLink(
	executor: DbExecutor,
	input: {
		id: string;
		groupId: string;
		platform: ChatPlatform;
		chatId: string;
		linkedBy: string | null;
		now: Date;
	},
) {
	const existing = await executor
		.select({ id: chatLinks.id, groupId: chatLinks.groupId })
		.from(chatLinks)
		.where(
			and(
				eq(chatLinks.platform, input.platform),
				eq(chatLinks.chatId, input.chatId),
			),
		)
		.limit(1);
	if (existing[0] && existing[0].groupId !== input.groupId) {
		await executor.delete(chatLinks).where(eq(chatLinks.id, existing[0].id));
	}
	const [row] = await executor
		.insert(chatLinks)
		.values({
			id: input.id,
			groupId: input.groupId,
			platform: input.platform,
			chatId: input.chatId,
			linkedBy: input.linkedBy,
			createdAt: input.now,
		})
		.onConflictDoUpdate({
			target: [chatLinks.platform, chatLinks.chatId],
			set: {
				groupId: input.groupId,
				linkedBy: input.linkedBy,
				createdAt: input.now,
			},
		})
		.returning();
	if (row === undefined) throw new Error("Failed to upsert chat link");
	return row;
}

export function findChatLinkByChat(
	executor: DbExecutor,
	input: { platform: ChatPlatform; chatId: string },
) {
	return executor
		.select({
			id: chatLinks.id,
			groupId: chatLinks.groupId,
			groupName: groups.name,
			groupArchivedAt: groups.archivedAt,
			platform: chatLinks.platform,
			chatId: chatLinks.chatId,
			createdAt: chatLinks.createdAt,
		})
		.from(chatLinks)
		.innerJoin(groups, eq(groups.id, chatLinks.groupId))
		.where(
			and(
				eq(chatLinks.platform, input.platform),
				eq(chatLinks.chatId, input.chatId),
			),
		)
		.limit(1)
		.then((rows) => rows[0] ?? null);
}

export function listGroupChatLinks(executor: DbExecutor, groupId: string) {
	return executor
		.select({
			id: chatLinks.id,
			platform: chatLinks.platform,
			chatId: chatLinks.chatId,
			createdAt: chatLinks.createdAt,
		})
		.from(chatLinks)
		.where(eq(chatLinks.groupId, groupId))
		.orderBy(asc(chatLinks.createdAt), asc(chatLinks.id));
}

export async function deleteGroupChatLink(
	executor: DbExecutor,
	input: { groupId: string; chatLinkId: string },
): Promise<boolean> {
	const rows = await executor
		.delete(chatLinks)
		.where(
			and(
				eq(chatLinks.id, input.chatLinkId),
				eq(chatLinks.groupId, input.groupId),
			),
		)
		.returning({ id: chatLinks.id });
	return rows.length > 0;
}

export async function findChatIdentity(
	executor: DbExecutor,
	input: { platform: ChatPlatform; platformUserId: string },
) {
	const [row] = await executor
		.select()
		.from(chatIdentities)
		.where(
			and(
				eq(chatIdentities.platform, input.platform),
				eq(chatIdentities.platformUserId, input.platformUserId),
			),
		)
		.limit(1);
	return row ?? null;
}

export function listUserChatIdentities(executor: DbExecutor, userId: string) {
	return executor
		.select({
			platform: chatIdentities.platform,
			createdAt: chatIdentities.createdAt,
		})
		.from(chatIdentities)
		.where(eq(chatIdentities.userId, userId))
		.orderBy(asc(chatIdentities.platform));
}

export async function upsertUserChatIdentity(
	executor: DbExecutor,
	input: {
		platform: ChatPlatform;
		platformUserId: string;
		userId: string;
		now: Date;
	},
): Promise<void> {
	await executor
		.delete(chatIdentities)
		.where(
			and(
				eq(chatIdentities.platform, input.platform),
				eq(chatIdentities.userId, input.userId),
			),
		);
	await executor.insert(chatIdentities).values({
		platform: input.platform,
		platformUserId: input.platformUserId,
		userId: input.userId,
		createdAt: input.now,
	});
}

export async function deleteUserChatIdentity(
	executor: DbExecutor,
	input: { userId: string; platform: ChatPlatform },
): Promise<boolean> {
	const rows = await executor
		.delete(chatIdentities)
		.where(
			and(
				eq(chatIdentities.userId, input.userId),
				eq(chatIdentities.platform, input.platform),
			),
		)
		.returning({ platform: chatIdentities.platform });
	return rows.length > 0;
}

export async function insertBotDraft(
	executor: DbExecutor,
	input: typeof botDrafts.$inferInsert,
): Promise<void> {
	await executor.insert(botDrafts).values(input);
}

export async function findBotDraftById(executor: DbExecutor, draftId: string) {
	const [row] = await executor
		.select()
		.from(botDrafts)
		.where(eq(botDrafts.id, draftId))
		.limit(1);
	return row ?? null;
}

export async function lockBotDraftById(executor: DbExecutor, draftId: string) {
	const [row] = await executor
		.select()
		.from(botDrafts)
		.where(eq(botDrafts.id, draftId))
		.for("update")
		.limit(1);
	return row ?? null;
}

export async function markBotDraftSaved(
	executor: DbExecutor,
	input: { draftId: string; transactionId: string; savedAt: Date },
): Promise<boolean> {
	const rows = await executor
		.update(botDrafts)
		.set({
			savedTransactionId: input.transactionId,
			savedAt: input.savedAt,
		})
		.where(
			and(
				eq(botDrafts.id, input.draftId),
				isNull(botDrafts.savedTransactionId),
			),
		)
		.returning({ id: botDrafts.id });
	return rows.length > 0;
}

export async function deleteBotDraftById(
	executor: DbExecutor,
	draftId: string,
): Promise<boolean> {
	const rows = await executor
		.delete(botDrafts)
		.where(and(eq(botDrafts.id, draftId), isNull(botDrafts.savedTransactionId)))
		.returning({ id: botDrafts.id });
	return rows.length > 0;
}

export async function findRecentSavedBotDraft(
	executor: DbExecutor,
	input: { chatLinkId: string; userId: string; since: Date },
) {
	const [row] = await executor
		.select()
		.from(botDrafts)
		.where(
			and(
				eq(botDrafts.chatLinkId, input.chatLinkId),
				eq(botDrafts.userId, input.userId),
				isNotNull(botDrafts.savedTransactionId),
				gt(botDrafts.savedAt, input.since),
			),
		)
		.orderBy(desc(botDrafts.savedAt), desc(botDrafts.id))
		.limit(1);
	return row ?? null;
}

export async function clearBotDraftSaved(
	executor: DbExecutor,
	draftId: string,
): Promise<void> {
	await executor.delete(botDrafts).where(eq(botDrafts.id, draftId));
}

export async function deleteBotUpdate(
	executor: DbExecutor,
	input: { platform: ChatPlatform; updateId: string },
): Promise<void> {
	await executor
		.delete(botUpdates)
		.where(
			and(
				eq(botUpdates.platform, input.platform),
				eq(botUpdates.updateId, input.updateId),
			),
		);
}

export async function pruneBotRecords(
	executor: DbExecutor,
	now: Date,
): Promise<{
	drafts: number;
	codes: number;
	updates: number;
	pairings: number;
}> {
	const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
	const deletedDrafts = await executor
		.delete(botDrafts)
		.where(
			or(
				and(isNull(botDrafts.savedTransactionId), lt(botDrafts.expiresAt, now)),
				and(isNotNull(botDrafts.savedAt), lt(botDrafts.savedAt, oneDayAgo)),
			),
		)
		.returning({ id: botDrafts.id });
	const deletedCodes = await executor
		.delete(chatLinkCodes)
		.where(
			or(
				lt(chatLinkCodes.expiresAt, oneDayAgo),
				and(
					isNotNull(chatLinkCodes.usedAt),
					lt(chatLinkCodes.usedAt, oneDayAgo),
				),
			),
		)
		.returning({ codeHash: chatLinkCodes.codeHash });
	const deletedUpdates = await executor
		.delete(botUpdates)
		.where(lt(botUpdates.createdAt, oneDayAgo))
		.returning({ updateId: botUpdates.updateId });
	const deletedPairings = await executor
		.delete(chatIdentityPairings)
		.where(
			or(
				lt(chatIdentityPairings.expiresAt, oneDayAgo),
				and(
					isNotNull(chatIdentityPairings.consumedAt),
					lt(chatIdentityPairings.consumedAt, oneDayAgo),
				),
			),
		)
		.returning({ id: chatIdentityPairings.id });
	return {
		drafts: deletedDrafts.length,
		codes: deletedCodes.length,
		updates: deletedUpdates.length,
		pairings: deletedPairings.length,
	};
}
