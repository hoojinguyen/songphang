import type { Config } from "../config.js";
import { createConsoleSender } from "./console-sender.js";
import { createTelegramSender } from "./telegram-sender.js";

export type ChatButton = {
	text: string;
	data?: string;
	url?: string;
};

export interface ChatSender {
	send(chatId: string, text: string, buttons?: ChatButton[]): Promise<void>;
	answerCallback(callbackId: string, text?: string): Promise<void>;
}

export function createChatSender(config: Config): ChatSender | null {
	if (config.telegramProvider === null) return null;
	if (config.telegramProvider === "console") return createConsoleSender();
	if (!config.telegramBotToken) {
		throw new Error("TELEGRAM_BOT_TOKEN is missing");
	}
	return createTelegramSender(config.telegramBotToken);
}
