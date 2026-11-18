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
		const deleted = await deleteBotDraftById(deps.db, draft.id);
		await sender.answerCallback(cb.id);
		if (deleted) {
			await sender.send(chatId, BOT_MESSAGES.dropped);
		}
		return;
	}

	const actor = await resolveActor(deps, {
		chatId,
		platformUserId: cb.from.id,
	});
	if (actor.kind === "chat_not_linked") {
		await sender.answerCallback(cb.id);
		await sender.send(chatId, BOT_MESSAGES.chatNotLinked);
		return;
	}
	if (actor.kind === "sender_not_linked") {
		await sender.answerCallback(cb.id);
		await replySenderNotLinked(deps, sender, {
			chatId,
			platformUserId: cb.from.id,
		});
		return;
	}
	if (actor.kind === "not_in_group") {
		await sender.answerCallback(cb.id);
		await sender.send(chatId, BOT_MESSAGES.notInGroup(actor.groupName));
		return;
	}
	if (actor.role === "viewer") {
		await sender.answerCallback(cb.id);
		await sender.send(chatId, BOT_MESSAGES.viewerCannotAdd);
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
		occurredAt: now.toISOString(),
		category: payload.data.category,
		categoryId: payload.data.categoryId,
		payers: payload.data.payers,
		split: payload.data.split,
	};

	const response = await runIdempotent(
		deps,
		{
			userId: actor.user.id,
			key: `bot-draft-${draft.id}`,
			onCommitted: () =>
				deps.events.publishChanged(actor.groupId, [
					"transactions",
					"balances",
					"activity",
					"budget",
				]),
			requestHash: hashRequest("POST", `/bot/drafts/${draft.id}`, request),
		},
		async (tx) => ({
			status: 201,
			body: await createTransaction(tx, {
				groupId: actor.groupId,
				userId: actor.user.id,
				request,
				now,
				enqueue: deps.enqueue,
			}),
		}),
	);

	const created = TransactionResponse.parse(response.body);
	const savedNow = await markBotDraftSaved(deps.db, {
		draftId: draft.id,
		transactionId: created.transaction.id,
		savedAt: now,
	});
	await sender.answerCallback(cb.id);
	if (savedNow) {
		const owner =
			created.transaction.approval.status === "pending"
				? await findGroupOwner(deps.db, actor.groupId)
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
