import type { ChatButton, ChatSender } from "./chat-sender.js";

const TELEGRAM_TIMEOUT_MS = 10_000;

type TelegramInlineButton =
	| { text: string; callback_data: string }
	| { text: string; url: string };

function toInlineButtons(buttons?: ChatButton[]): TelegramInlineButton[] {
	if (!buttons || buttons.length === 0) return [];
	const result: TelegramInlineButton[] = [];
	for (const button of buttons) {
		if (button.data !== undefined) {
			result.push({ text: button.text, callback_data: button.data });
		} else if (button.url !== undefined) {
			result.push({ text: button.text, url: button.url });
		}
	}
	return result;
}

export function createTelegramSender(botToken: string): ChatSender {
	async function post(method: string, body: Record<string, unknown>) {
		try {
			const response = await fetch(
				`https://api.telegram.org/bot${botToken}/${method}`,
				{
					method: "POST",
					headers: { "Content-Type": "application/json" },
					body: JSON.stringify(body),
					signal: AbortSignal.timeout(TELEGRAM_TIMEOUT_MS),
				},
			);
			if (!response.ok) {
				console.error(
					JSON.stringify({
						event: "telegram.api.error",
						method,
						status: response.status,
					}),
				);
			}
		} catch {
			console.error(
				JSON.stringify({
					event: "telegram.api.error",
					method,
					status: null,
				}),
			);
		}
	}

	return {
		async send(chatId: string, text: string, buttons?: ChatButton[]) {
			const row = toInlineButtons(buttons);
			await post("sendMessage", {
				chat_id: chatId,
				text,
				...(row.length > 0 ? { reply_markup: { inline_keyboard: [row] } } : {}),
			});
		},
		async answerCallback(callbackId: string, text?: string) {
			await post("answerCallbackQuery", {
				callback_query_id: callbackId,
				...(text !== undefined ? { text } : {}),
			});
		},
	};
}
