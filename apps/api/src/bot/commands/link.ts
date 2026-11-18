import type { AppDeps } from "../../app.js";
import { BOT_MESSAGES } from "../../bot-messages.js";
import { redeemGroupChatLinkCode } from "../../services/chat-links.js";
import type { ChatSender } from "../chat-sender.js";

export async function handleLinkCommand(
	deps: AppDeps,
	sender: ChatSender,
	input: { chatId: string; chatType: string; arg: string },
): Promise<void> {
	if (input.chatType !== "group" && input.chatType !== "supergroup") {
		await sender.send(input.chatId, BOT_MESSAGES.badOrExpiredCode);
		return;
	}
	const linked = await redeemGroupChatLinkCode(deps, {
		chatId: input.chatId,
		rawCode: input.arg,
	});
	await sender.send(
		input.chatId,
		linked.ok
			? BOT_MESSAGES.chatLinked(linked.groupName)
			: BOT_MESSAGES.badOrExpiredCode,
	);
}
