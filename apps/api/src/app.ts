import { OpenAPIHono } from "@hono/zod-openapi";
import type { Db } from "@songphang/db";
import { uuidv7 } from "uuidv7";
import type { Config } from "./config.js";
import { AppError, handleError, validateRequest } from "./errors.js";
import { registerHealthRoute } from "./routes/health.js";

export type AppEnv = { Variables: { requestId: string } };
export type AppDeps = { config: Config; db: Db; now: () => Date };

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
	app.notFound(() => {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	});
	registerHealthRoute(app, deps.db);
	app.doc31("/api/v1/openapi.json", {
		openapi: "3.1.0",
		info: { title: "Song Phang API", version: "0.0.0" },
	});
	return app;
}
