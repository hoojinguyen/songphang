import type { AppDeps } from "../app.js";
import { handleBotCallback } from "./callbacks.js";
import type { ChatSender } from "./chat-sender.js";
import { handleBalancesCommand } from "./commands/balances.js";
import { handleExpenseCommand } from "./commands/expense.js";
import { handleHelpCommand } from "./commands/help.js";
import { handleLinkCommand } from "./commands/link.js";
import { handleUndoCommand } from "./commands/undo.js";
import {
	handleTelegramPairingCallback,
	handleTelegramPairingStartCommand,
} from "./pairing.js";
import { parseBotCommand, type TelegramUpdate } from "./telegram-update.js";

export async function dispatchWebhookUpdate(
	deps: AppDeps,
	sender: ChatSender,
	update: TelegramUpdate,
): Promise<void> {
	if (update.callback_query) {
		const handledPairing = await handleTelegramPairingCallback(
			deps,
			sender,
			update.callback_query,
		);
		if (handledPairing) return;
		await handleBotCallback(deps, sender, update.callback_query);
		return;
	}
	if (!update.message?.text || !update.message.from) return;

	const parsed = parseBotCommand(
		update.message.text,
		deps.config.telegramBotUsername,
	);
	if (parsed === null) return;

	const chatId = update.message.chat.id;
	const chatType = update.message.chat.type;
	const platformUserId = update.message.from.id;
	const platformUserName = update.message.from.first_name?.trim() || null;

	switch (parsed.command) {
		case "lienket":
			await handleLinkCommand(deps, sender, {
				chatId,
				chatType,
				arg: parsed.arg,
			});
			return;
		case "chi":
			await handleExpenseCommand(deps, sender, {
				chatId,
				platformUserId,
				arg: parsed.arg,
			});
			return;
		case "sodu":
			await handleBalancesCommand(deps, sender, { chatId, platformUserId });
			return;
		case "huy":
			await handleUndoCommand(deps, sender, { chatId, platformUserId });
			return;
		case "start":
			if (parsed.arg.length > 0) {
				await handleTelegramPairingStartCommand(deps, sender, {
					chatId,
					chatType,
					platformUserId,
					platformUserName,
					rawSecret: parsed.arg,
				});
				return;
			}
			await handleHelpCommand(deps, sender, { chatId, chatType });
			return;
		case "trogiup":
			await handleHelpCommand(deps, sender, { chatId, chatType });
			return;
		default:
			return;
	}
}
