import type { AppDeps } from "../app.js";
import { handleBotCallback } from "./callbacks.js";
import type { ChatSender } from "./chat-sender.js";
import { handleChiCommand } from "./commands/chi.js";
import { handleHuyCommand } from "./commands/huy.js";
import { handleLienketCommand } from "./commands/lienket.js";
import { handleSoduCommand } from "./commands/sodu.js";
import { handleTrogiupCommand } from "./commands/trogiup.js";
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
			await handleLienketCommand(deps, sender, { chatId, arg: parsed.arg });
			return;
		case "chi":
			await handleChiCommand(deps, sender, {
				chatId,
				platformUserId,
				arg: parsed.arg,
			});
			return;
		case "sodu":
			await handleSoduCommand(deps, sender, { chatId, platformUserId });
			return;
		case "huy":
			await handleHuyCommand(deps, sender, { chatId, platformUserId });
			return;
		case "trogiup":
		case "start":
			await handleTrogiupCommand(deps, sender, { chatId });
			return;
		default:
			return;
	}
}
