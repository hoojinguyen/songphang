import { findChatLinkByChat } from "@songphang/db";
import type { AppDeps } from "../../app.js";
import { BOT_MESSAGES } from "../../bot-messages.js";
import type { ChatSender } from "../chat-sender.js";

export async function handleTrogiupCommand(
	deps: AppDeps,
	sender: ChatSender,
	input: { chatId: string },
): Promise<void> {
	const link = await findChatLinkByChat(deps.db, {
		platform: "telegram",
		chatId: input.chatId,
	});
	if (link === null) {
		await sender.send(input.chatId, BOT_MESSAGES.chatNotLinked);
		return;
	}
	await sender.send(input.chatId, BOT_MESSAGES.help);
}
