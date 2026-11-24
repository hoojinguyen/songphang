import {
	type CreateTransactionRequest,
	TransactionResponse,
} from "@songphang/contract";
import {
	deleteBotDraftById,
	findBotDraftById,
	findChatIdentity,
	findChatLinkByChat,
	findGroupOwner,
	findUserById,
	lockBotDraftById,
	markBotDraftSaved,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { BOT_MESSAGES } from "../bot-messages.js";
import { hashRequest, runIdempotent } from "../idempotency.js";
import { createTransaction } from "../services/transactions.js";
import type { ChatSender } from "./chat-sender.js";
import { BotDraftPayload } from "./draft-payload.js";
import { replySenderNotLinked, resolveActor } from "./resolve-actor.js";
import type { TelegramUpdate } from "./telegram-update.js";

const CALLBACK_PATTERN = /^([sd]):([0-9a-f-]{36})$/i;

type BotSaveAbortReason =
	| "dropped"
	| "expired"
	| "already_saved"
	| "chat_not_linked"
	| "sender_not_linked"
	| "not_in_group"
	| "viewer";

class BotSaveAbortError extends Error {
	constructor(
		readonly reason: BotSaveAbortReason,
		readonly groupName?: string,
	) {
		super(reason);
	}
}

async function replySaveAbort(
	deps: AppDeps,
	sender: ChatSender,
	input: {
		cbId: string;
		chatId: string;
		platformUserId: string;
		error: BotSaveAbortError;
	},
): Promise<void> {
	await sender.answerCallback(input.cbId);
	switch (input.error.reason) {
		case "expired":
			await sender.send(input.chatId, BOT_MESSAGES.draftExpired);
			return;
		case "chat_not_linked":
			await sender.send(input.chatId, BOT_MESSAGES.chatNotLinked);
			return;
		case "sender_not_linked":
			await replySenderNotLinked(deps, sender, {
				chatId: input.chatId,
				platformUserId: input.platformUserId,
			});
			return;
		case "not_in_group":
			await sender.send(
				input.chatId,
				BOT_MESSAGES.notInGroup(input.error.groupName ?? ""),
			);
			return;
		case "viewer":
			await sender.send(input.chatId, BOT_MESSAGES.viewerCannotAdd);
			return;
		case "dropped":
		case "already_saved":
			return;
	}
}

export async function handleBotCallback(
	deps: AppDeps,
	sender: ChatSender,
	cb: NonNullable<TelegramUpdate["callback_query"]>,
): Promise<void> {
	const chatId = cb.message?.chat.id;
	const match = cb.data?.match(CALLBACK_PATTERN);
	if (!chatId || !match?.[1] || !match[2]) {
		await sender.answerCallback(cb.id);
		return;
	}

	const action = match[1].toLowerCase();
	const draftId = match[2].toLowerCase();
	const [chatLink, draft] = await Promise.all([
		findChatLinkByChat(deps.db, { platform: "telegram", chatId }),
		findBotDraftById(deps.db, draftId),
	]);
	if (chatLink === null || draft === null || draft.chatLinkId !== chatLink.id) {
		await sender.answerCallback(cb.id);
		return;
	}

	const identity = await findChatIdentity(deps.db, {
		platform: "telegram",
		platformUserId: cb.from.id,
	});
	if (identity === null || identity.userId !== draft.userId) {
		const draftOwner = await findUserById(deps.db, draft.userId);
		await sender.answerCallback(
			cb.id,
			BOT_MESSAGES.onlySenderCanSave(draftOwner?.name ?? ""),
		);
		return;
	}

	if (draft.savedTransactionId !== null) {
		await sender.answerCallback(cb.id);
		return;
	}

	const now = deps.now();
	if (draft.expiresAt.getTime() <= now.getTime()) {
		await sender.answerCallback(cb.id);
		await sender.send(chatId, BOT_MESSAGES.draftExpired);
		return;
	}

	if (action === "d") {
		const deleted = await deps.db.transaction(async (tx) => {
			const locked = await lockBotDraftById(tx, draft.id);
			if (locked === null || locked.savedTransactionId !== null) {
				return false;
			}
			return deleteBotDraftById(tx, locked.id);
		});
		await sender.answerCallback(cb.id);
		if (deleted) {
			await sender.send(chatId, BOT_MESSAGES.dropped);
		}
		return;
	}

	const payload = BotDraftPayload.safeParse(draft.draft);
	if (!payload.success) {
		await sender.answerCallback(cb.id);
		return;
	}

	const request: CreateTransactionRequest = {
		type: "expense",
		description: payload.data.description,
		amount: payload.data.amount,
		occurredAt: payload.data.occurredAt ?? draft.createdAt.toISOString(),
		category: payload.data.category,
		categoryId: payload.data.categoryId,
		payers: payload.data.payers,
		split: payload.data.split,
	};

	let didCreate = false;
	let committedGroupId = chatLink.groupId;
	let response: { status: number; body: unknown };
	try {
		response = await runIdempotent(
			deps,
			{
				userId: draft.userId,
				key: `bot-draft-${draft.id}`,
				onCommitted: () =>
					deps.events.publishChanged(committedGroupId, [
						"transactions",
						"balances",
						"activity",
						"budget",
					]),
				requestHash: hashRequest("POST", `/bot/drafts/${draft.id}`, request),
			},
			async (tx) => {
				const locked = await lockBotDraftById(tx, draft.id);
				if (locked === null) {
					throw new BotSaveAbortError("dropped");
				}
				if (locked.savedTransactionId !== null) {
					throw new BotSaveAbortError("already_saved");
				}
				if (locked.expiresAt.getTime() <= now.getTime()) {
					throw new BotSaveAbortError("expired");
				}

				const actor = await resolveActor(
					{ db: tx },
					{ chatId, platformUserId: cb.from.id },
				);
				if (actor.kind === "chat_not_linked") {
					throw new BotSaveAbortError("chat_not_linked");
				}
				if (actor.kind === "sender_not_linked") {
					throw new BotSaveAbortError("sender_not_linked");
				}
				if (actor.kind === "not_in_group") {
					throw new BotSaveAbortError("not_in_group", actor.groupName);
				}
				if (actor.role === "viewer") {
					throw new BotSaveAbortError("viewer");
				}
				if (
					actor.user.id !== locked.userId ||
					actor.chatLink.id !== locked.chatLinkId
				) {
					throw new BotSaveAbortError("dropped");
				}

				committedGroupId = actor.groupId;
				const createdTx = await createTransaction(tx, {
					groupId: actor.groupId,
					userId: actor.user.id,
					request,
					now,
					enqueue: deps.enqueue,
					pushEnabled: Boolean(deps.config.pushProvider),
				});
				const savedNow = await markBotDraftSaved(tx, {
					draftId: locked.id,
					transactionId: createdTx.transaction.id,
					savedAt: now,
				});
				if (!savedNow) {
					throw new BotSaveAbortError("already_saved");
				}
				didCreate = true;
				return { status: 201, body: createdTx };
			},
		);
	} catch (error) {
		if (error instanceof BotSaveAbortError) {
			await replySaveAbort(deps, sender, {
				cbId: cb.id,
				chatId,
				platformUserId: cb.from.id,
				error,
			});
			return;
		}
		throw error;
	}

	const created = TransactionResponse.parse(response.body);
	let savedNow = didCreate;
	if (!savedNow) {
		savedNow = await markBotDraftSaved(deps.db, {
			draftId: draft.id,
			transactionId: created.transaction.id,
			savedAt: now,
		});
	}
	await sender.answerCallback(cb.id);
	if (savedNow) {
		const owner =
			created.transaction.approval.status === "pending"
				? await findGroupOwner(deps.db, committedGroupId)
				: null;
		await sender.send(
			chatId,
			BOT_MESSAGES.saved(
				created.transaction.description,
				created.transaction.amount,
				owner?.name,
			),
		);
	}
}
