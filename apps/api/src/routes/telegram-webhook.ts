import { timingSafeEqual } from "node:crypto";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { recordBotUpdateIfNew } from "@songphang/db";
import type { AppDeps, AppEnv } from "../app.js";
import { createChatSender } from "../bot/chat-sender.js";
import { dispatchWebhookUpdate } from "../bot/dispatch.js";
import { extractChatId, TelegramUpdate } from "../bot/telegram-update.js";
import { BOT_MESSAGES } from "../bot-messages.js";
import { AppError } from "../errors.js";

function secretMatches(
	header: string | undefined,
	expected: string | undefined,
): boolean {
	if (!header || !expected) return false;
	const actualBuf = Buffer.from(header, "utf8");
	const expectedBuf = Buffer.from(expected, "utf8");
	if (actualBuf.length !== expectedBuf.length) {
		timingSafeEqual(expectedBuf, expectedBuf);
		return false;
	}
	return timingSafeEqual(actualBuf, expectedBuf);
}

export function registerTelegramWebhookRoute(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	const sender = deps.chatSender ?? createChatSender(deps.config);

	app.post("/api/v1/bots/telegram/webhook", async (context) => {
		if (
			deps.config.telegramProvider === null ||
			sender === null ||
			!secretMatches(
				context.req.header("X-Telegram-Bot-Api-Secret-Token"),
				deps.config.telegramWebhookSecret,
			)
		) {
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		}

		let rawJson: unknown;
		try {
			const rawText = await context.req.text();
			rawJson = JSON.parse(rawText);
		} catch {
			return context.json({}, 200);
		}

		const parsed = TelegramUpdate.safeParse(rawJson);
		if (!parsed.success) {
			return context.json({}, 200);
		}

		try {
			const isNew = await recordBotUpdateIfNew(deps.db, {
				platform: "telegram",
				updateId: parsed.data.update_id,
				now: deps.now(),
			});
			if (!isNew) {
				return context.json({}, 200);
			}

			const chatId = extractChatId(parsed.data);
			if (chatId !== null) {
				const quota = deps.rateLimiter.consumeQuota({
					name: "telegram_chat_updates",
					max: 30,
					windowMs: 60_000,
					subject: chatId,
				});
				if (!quota.allowed) {
					if (quota.notifyExceeded) {
						await sender.send(chatId, BOT_MESSAGES.tooManyMessages);
					}
					return context.json({}, 200);
				}
			}

			await dispatchWebhookUpdate(deps, sender, parsed.data);
		} catch {
			console.error(
				JSON.stringify({
					event: "telegram.webhook.error",
					requestId: context.var.requestId,
				}),
			);
		}
		return context.json({}, 200);
	});
}
