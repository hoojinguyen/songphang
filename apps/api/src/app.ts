import { OpenAPIHono } from "@hono/zod-openapi";
import type { GroupRole, UserDto } from "@songphang/contract";
import type { Db } from "@songphang/db";
import type { FileStore } from "@songphang/storage";
import { bodyLimit } from "hono/body-limit";
import { uuidv7 } from "uuidv7";
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
import { registerReceiptScanRoutes } from "./routes/receipt-scans.js";
import { registerSettlementRoutes } from "./routes/settlement-requests.js";
import { registerStatsRoutes } from "./routes/stats.js";
import { registerTransactionRoutes } from "./routes/transactions.js";

export type AppEnv = {
	Variables: {
		requestId: string;
		user: UserDto;
		sessionToken: string;
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
};

export function createApp(deps: AppDeps): OpenAPIHono<AppEnv> {
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
	registerHealthRoute(app, deps.db);
	registerFeatureRoute(app, deps);
	registerMeRoute(app, deps);
	registerGroupRoutes(app, deps);
	registerEventRoutes(app, deps);
	registerGroupUserRoutes(app, deps);
	registerInviteRoutes(app, deps);
	registerMemberRoutes(app, deps);
	registerFundRoutes(app, deps);
	registerCategoryRoutes(app, deps);
	registerSettlementRoutes(app, deps);
	registerTransactionRoutes(app, deps);
	registerAttachmentRoutes(app, deps);
	registerReceiptScanRoutes(app, deps);
	registerBalanceRoutes(app, deps);
	registerBudgetRoutes(app, deps);
	registerStatsRoutes(app, deps);
	registerExportRoutes(app, deps);
	registerActivityRoutes(app, deps);
	registerAuthRoutes(app, deps);
	registerGoogleRoutes(app, deps);
	if (deps.config.devLogin && deps.config.appEnv === "development") {
		registerDevRoutes(app, deps);
	}
	app.doc31("/api/v1/openapi.json", {
		openapi: "3.1.0",
		info: { title: "Song Phang API", version: "0.0.0" },
	});
	return app;
}
