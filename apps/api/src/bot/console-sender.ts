import type { ChatButton, ChatSender } from "./chat-sender.js";

export function createConsoleSender(): ChatSender {
	return {
		async send(chatId: string, text: string, buttons?: ChatButton[]) {
			console.log(
				JSON.stringify({
					chatId,
					text,
					...(buttons && buttons.length > 0 ? { buttons } : {}),
				}),
			);
		},
		async answerCallback(callbackId: string, text?: string) {
			console.log(
				JSON.stringify({
					callbackId,
					...(text !== undefined ? { text } : {}),
				}),
			);
		},
	};
}
