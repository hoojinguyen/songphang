import { OpenAPIHono } from "@hono/zod-openapi";
import type { GroupRole, UserDto } from "@songphang/contract";
import type { Db, DbSessionClient } from "@songphang/db";
import type { FileStore } from "@songphang/storage";
import { bodyLimit } from "hono/body-limit";
import { uuidv7 } from "uuidv7";
import type { SentenceAi } from "./ai/sentence-ai.js";
import {
	type AppleKeySetProvider,
	createAppleKeySetProvider,
} from "./auth/apple/key-set.js";
import {
	type AppleTokenAdapter,
	createAppleTokenAdapter,
} from "./auth/apple/token-adapter.js";
import type { ChatSender } from "./bot/chat-sender.js";
import type { Config } from "./config.js";
import { AppError, handleError, validateRequest } from "./errors.js";
import type { createEventHub } from "./events/hub.js";
import type { Mailer } from "./mailer.js";
import type { EnqueueFn } from "./queue.js";
import type { createRateLimiter } from "./rate-limit.js";
import { registerActivityRoutes } from "./routes/activity.js";
import { registerAttachmentRoutes } from "./routes/attachments.js";
import { registerAuthRoutes } from "./routes/auth.js";
import { registerBalanceRoutes } from "./routes/balances.js";
import { registerBudgetRoutes } from "./routes/budget.js";
import { registerCategoryRoutes } from "./routes/categories.js";
import { registerChatLinkRoutes } from "./routes/chat-links.js";
import { registerCommentRoutes } from "./routes/comments.js";
import { registerDevRoutes } from "./routes/dev.js";
import { registerEventRoutes } from "./routes/events.js";
import { registerExportRoutes } from "./routes/export.js";
import { registerFeatureRoute } from "./routes/features.js";
import { registerFundRoutes } from "./routes/fund.js";
import { registerGoogleRoutes } from "./routes/google.js";
import { registerGroupUserRoutes } from "./routes/group-users.js";
import { registerGroupRoutes } from "./routes/groups.js";
import { registerHealthRoute } from "./routes/health.js";
import { registerInviteRoutes } from "./routes/invites.js";
import { registerMeRoute } from "./routes/me.js";
import { registerMemberRoutes } from "./routes/members.js";
import { registerMobileAuthRoutes } from "./routes/mobile-auth.js";
import { registerNotificationRoutes } from "./routes/notifications.js";
import { registerReceiptScanRoutes } from "./routes/receipt-scans.js";
import { registerReminderRoutes } from "./routes/reminders.js";
import { registerSettlementRoutes } from "./routes/settlement-requests.js";
import { registerSettlementVaultRoutes } from "./routes/settlement-vault.js";
import { registerStatsRoutes } from "./routes/stats.js";
import { registerTelegramWebhookRoute } from "./routes/telegram-webhook.js";
import { registerTransactionRoutes } from "./routes/transactions.js";
import { registerUnsubscribeRoutes } from "./routes/unsubscribe.js";

export type AppEnv = {
	Variables: {
		requestId: string;
		user: UserDto;
		sessionToken: string;
		sessionId: string;
		sessionClient: DbSessionClient;
		sessionTransport: "bearer" | "cookie" | "mixed";
		authEmail: string;
		groupAccess: { groupId: string; role: GroupRole; memberId: string | null };
	};
};
export type AppDeps = {
	events: ReturnType<typeof createEventHub>;
	config: Config;
	db: Db;
	now: () => Date;
	mailer: Mailer;
	rateLimiter: ReturnType<typeof createRateLimiter>;
	enqueue: EnqueueFn;
	fileStore: FileStore;
	sentenceAi?: SentenceAi | null;
	chatSender?: ChatSender | null;
	appleKeySet?: AppleKeySetProvider | null;
	appleTokenAdapter?: AppleTokenAdapter | null;
};

export const OPENAPI_DOCUMENT_CONFIG = {
	openapi: "3.1.0",
	info: {
		title: "Song Phang API",
		version: "1.0.0",
		description:
			"Version 1 additive-only HTTP contract for Song Phang web and native clients. Clients must ignore unknown object fields and map unknown enum values to safe fallbacks (for example read-only or other). App versions use three-component major.minor.patch strings.",
	},
} as const;

export function createApp(deps: AppDeps): OpenAPIHono<AppEnv> {
	const resolvedDeps: AppDeps = deps.config.appleProvider
		? {
				...deps,
				appleKeySet:
					deps.appleKeySet ?? createAppleKeySetProvider(deps.config, deps.now),
				appleTokenAdapter:
					deps.appleTokenAdapter ??
					createAppleTokenAdapter(deps.config, deps.now),
			}
		: deps;
	const app = new OpenAPIHono<AppEnv>({
		defaultHook: validateRequest,
	});
	app.use("*", async (context, next) => {
		const requestId = uuidv7();
		context.set("requestId", requestId);
		context.header("X-Request-Id", requestId);
		await next();
	});
	app.onError(handleError);
	const defaultBodyLimit = bodyLimit({
		maxSize: 100 * 1024,
		onError: () => {
			throw new AppError(400, "VALIDATION_FAILED", "Request body is too large");
		},
	});
	app.use("*", async (context, next) => {
		if (
			context.req.method === "POST" &&
			/^\/api\/v1\/groups\/[^/]+\/attachments$/.test(context.req.path)
		) {
			await next();
			return;
		}
		await defaultBodyLimit(context, next);
	});
	app.notFound(() => {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	});
	registerHealthRoute(app, resolvedDeps.db);
	registerFeatureRoute(app, resolvedDeps);
	registerMeRoute(app, resolvedDeps);
	registerNotificationRoutes(app, resolvedDeps);
	registerUnsubscribeRoutes(app, resolvedDeps);
	registerGroupRoutes(app, resolvedDeps);
	registerEventRoutes(app, resolvedDeps);
	registerGroupUserRoutes(app, resolvedDeps);
	registerInviteRoutes(app, resolvedDeps);
	registerMemberRoutes(app, resolvedDeps);
	registerFundRoutes(app, resolvedDeps);
	registerCategoryRoutes(app, resolvedDeps);
	registerSettlementRoutes(app, resolvedDeps);
	registerSettlementVaultRoutes(app, resolvedDeps);
	registerTransactionRoutes(app, resolvedDeps);
	registerCommentRoutes(app, resolvedDeps);
	registerAttachmentRoutes(app, resolvedDeps);
	registerReceiptScanRoutes(app, resolvedDeps);
	registerBalanceRoutes(app, resolvedDeps);
	registerReminderRoutes(app, resolvedDeps);
	registerChatLinkRoutes(app, resolvedDeps);
	registerTelegramWebhookRoute(app, resolvedDeps);
	registerBudgetRoutes(app, resolvedDeps);
	registerStatsRoutes(app, resolvedDeps);
	registerExportRoutes(app, resolvedDeps);
	registerActivityRoutes(app, resolvedDeps);
	registerAuthRoutes(app, resolvedDeps);
	registerMobileAuthRoutes(app, resolvedDeps);
	registerGoogleRoutes(app, resolvedDeps);
	if (
		resolvedDeps.config.devLogin &&
		resolvedDeps.config.appEnv === "development"
	) {
		registerDevRoutes(app, resolvedDeps);
	}
	app.doc31("/api/v1/openapi.json", OPENAPI_DOCUMENT_CONFIG);
	return app;
}
