import { z } from "@hono/zod-openapi";

const StringId = z.union([
	z.string().min(1).max(64),
	z.number().int().transform(String),
]);

const TelegramFrom = z.object({
	id: StringId,
	first_name: z.string().max(256).optional(),
});

const TelegramChat = z.object({
	id: StringId,
	type: z.string().max(32),
});

const TelegramMessage = z.object({
	message_id: StringId,
	from: TelegramFrom.optional(),
	chat: TelegramChat,
	text: z.string().max(1000).optional(),
});

const TelegramCallbackQuery = z.object({
	id: z.string().min(1).max(128),
	from: TelegramFrom,
	message: z
		.object({
			message_id: StringId.optional(),
			chat: TelegramChat,
		})
		.optional(),
	data: z.string().max(64).optional(),
});

export const TelegramUpdate = z.object({
	update_id: StringId,
	message: TelegramMessage.optional(),
	callback_query: TelegramCallbackQuery.optional(),
});
export type TelegramUpdate = z.infer<typeof TelegramUpdate>;

export function extractChatId(update: TelegramUpdate): string | null {
	if (update.message) return update.message.chat.id;
	if (update.callback_query?.message) {
		return update.callback_query.message.chat.id;
	}
	return null;
}

export function parseBotCommand(
	text: string,
	botUsername: string | undefined,
): { command: string; arg: string } | null {
	const trimmed = text.trim();
	const match = trimmed.match(
		/^\/([a-zA-Z0-9_]+)(?:@([a-zA-Z0-9_]+))?(?:\s+([\s\S]*))?$/,
	);
	if (!match?.[1]) return null;
	const command = match[1].toLowerCase();
	const mention = match[2];
	if (
		mention !== undefined &&
		botUsername !== undefined &&
		mention.toLowerCase() !== botUsername.toLowerCase()
	) {
		return null;
	}
	if (mention !== undefined && botUsername === undefined) {
		return null;
	}
	return { command, arg: (match[3] ?? "").trim() };
}
