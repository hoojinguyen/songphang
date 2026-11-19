import { findChatLinkByChat } from "@songphang/db";
import type { AppDeps } from "../../app.js";
import { BOT_MESSAGES } from "../../bot-messages.js";
import type { ChatSender } from "../chat-sender.js";

export async function handleHelpCommand(
	deps: AppDeps,
	sender: ChatSender,
	input: { chatId: string; chatType: string },
): Promise<void> {
	if (input.chatType === "private") {
		await sender.send(input.chatId, BOT_MESSAGES.privateStartHelp);
		return;
	}
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
