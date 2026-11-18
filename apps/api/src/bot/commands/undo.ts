import { clearBotDraftSaved, findRecentSavedBotDraft } from "@songphang/db";
import type { AppDeps } from "../../app.js";
import { BOT_MESSAGES } from "../../bot-messages.js";
import { AppError } from "../../errors.js";
import { setTransactionDeleted } from "../../services/transaction-changes.js";
import type { ChatSender } from "../chat-sender.js";
import { LINK_CODE_TTL_MS } from "../link-codes.js";
import { replySenderNotLinked, resolveActor } from "../resolve-actor.js";

export async function handleUndoCommand(
	deps: AppDeps,
	sender: ChatSender,
	input: { chatId: string; platformUserId: string },
): Promise<void> {
	const actor = await resolveActor(deps, input);
	if (actor.kind === "chat_not_linked") {
		await sender.send(input.chatId, BOT_MESSAGES.chatNotLinked);
		return;
	}
	if (actor.kind === "sender_not_linked") {
		await replySenderNotLinked(deps, sender, input);
		return;
	}
	if (actor.kind === "not_in_group") {
		await sender.send(input.chatId, BOT_MESSAGES.notInGroup(actor.groupName));
		return;
	}
	if (actor.role === "viewer") {
		await sender.send(input.chatId, BOT_MESSAGES.viewerCannotAdd);
		return;
	}

	const since = new Date(deps.now().getTime() - LINK_CODE_TTL_MS);
	const recent = await findRecentSavedBotDraft(deps.db, {
		chatLinkId: actor.chatLink.id,
		userId: actor.user.id,
		since,
	});
	if (recent === null || recent.savedTransactionId === null) {
		await sender.send(input.chatId, BOT_MESSAGES.huyNothing);
		return;
	}

	try {
		const deleted = await setTransactionDeleted(deps, {
			groupId: actor.groupId,
			id: recent.savedTransactionId,
			userId: actor.user.id,
			restore: false,
		});
		await clearBotDraftSaved(deps.db, recent.id);
		await sender.send(
			input.chatId,
			BOT_MESSAGES.huyDone(
				deleted.transaction.description,
				deleted.transaction.amount,
			),
		);
	} catch (error) {
		if (error instanceof AppError && error.code === "NOT_FOUND") {
			await clearBotDraftSaved(deps.db, recent.id);
			await sender.send(input.chatId, BOT_MESSAGES.huyNothing);
			return;
		}
		throw error;
	}
}
