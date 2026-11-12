import { OpenAPIHono } from "@hono/zod-openapi";
import type { GroupRole, UserDto } from "@songphang/contract";
import type { Db } from "@songphang/db";
import { bodyLimit } from "hono/body-limit";
import { uuidv7 } from "uuidv7";
import type { Config } from "./config.js";
import { AppError, handleError, validateRequest } from "./errors.js";
import type { Mailer } from "./mailer.js";
import { registerAuthRoutes } from "./routes/auth.js";
import { registerBalanceRoutes } from "./routes/balances.js";
import { registerDevRoutes } from "./routes/dev.js";
import { registerGroupRoutes } from "./routes/groups.js";
import { registerHealthRoute } from "./routes/health.js";
import { registerMeRoute } from "./routes/me.js";
import { registerMemberRoutes } from "./routes/members.js";
import { registerTransactionRoutes } from "./routes/transactions.js";

export type AppEnv = {
	Variables: {
		requestId: string;
		user: UserDto;
		sessionToken: string;
		groupAccess: { groupId: string; role: GroupRole; memberId: string | null };
	};
};
export type AppDeps = {
	config: Config;
	db: Db;
	now: () => Date;
	mailer: Mailer;
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
	app.use(
		"*",
		bodyLimit({
			maxSize: 100 * 1024,
			onError: () => {
				throw new AppError(
					400,
					"VALIDATION_FAILED",
					"Request body is too large",
				);
			},
		}),
	);
	app.notFound(() => {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	});
	registerHealthRoute(app, deps.db);
	registerMeRoute(app, deps);
	registerGroupRoutes(app, deps);
	registerMemberRoutes(app, deps);
	registerTransactionRoutes(app, deps);
	registerBalanceRoutes(app, deps);
	registerAuthRoutes(app, deps);
	if (deps.config.devLogin && deps.config.appEnv === "development") {
		registerDevRoutes(app, deps);
	}
	app.doc31("/api/v1/openapi.json", {
		openapi: "3.1.0",
		info: { title: "Song Phang API", version: "0.0.0" },
	});
	return app;
}
