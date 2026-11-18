import type { AppDeps } from "../app.js";
import { handleBotCallback } from "./callbacks.js";
import type { ChatSender } from "./chat-sender.js";
import { handleBalancesCommand } from "./commands/balances.js";
import { handleExpenseCommand } from "./commands/expense.js";
import { handleHelpCommand } from "./commands/help.js";
import { handleLinkCommand } from "./commands/link.js";
import { handleUndoCommand } from "./commands/undo.js";
import { parseBotCommand, type TelegramUpdate } from "./telegram-update.js";

export async function dispatchWebhookUpdate(
	deps: AppDeps,
	sender: ChatSender,
	update: TelegramUpdate,
): Promise<void> {
	if (update.callback_query) {
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
	const platformUserId = update.message.from.id;

	switch (parsed.command) {
		case "lienket":
			await handleLinkCommand(deps, sender, { chatId, arg: parsed.arg });
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
		case "trogiup":
		case "start":
			await handleHelpCommand(deps, sender, { chatId });
			return;
		default:
			return;
	}
}
