import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import {
	DevLoginRequest,
	DevUsersResponse,
	ErrorResponse,
} from "@songphang/contract";
import { type Db, listUsers } from "@songphang/db";
import { setCookie } from "hono/cookie";
import type { AppDeps, AppEnv } from "../app.js";
import { requireSameOrigin } from "../auth/middleware.js";
import {
	createSession,
	SESSION_COOKIE,
	sessionCookieAttributes,
} from "../auth/sessions.js";

async function listAvailableUsers(db: Db) {
	return DevUsersResponse.parse({ users: await listUsers(db) });
}

const usersRoute = createRoute({
	method: "get",
	path: "/api/v1/dev/users",
	responses: {
		200: {
			description: "Available users",
			content: { "application/json": { schema: DevUsersResponse } },
		},
	},
});

const loginRoute = createRoute({
	method: "post",
	path: "/api/v1/dev/login",
	request: {
		headers: z.object({ "user-agent": z.string().max(1024).optional() }),
		body: {
			required: true,
			content: { "application/json": { schema: DevLoginRequest } },
		},
	},
	responses: {
		204: { description: "Signed in" },
		400: {
			description: "Invalid input",
			content: { "application/json": { schema: ErrorResponse } },
		},
		404: {
			description: "User not found",
			content: { "application/json": { schema: ErrorResponse } },
		},
	},
});

export function registerDevRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	app.openapi(usersRoute, async (context) =>
		context.json(await listAvailableUsers(deps.db), 200),
	);
	app.openapi(
		{ ...loginRoute, middleware: [requireSameOrigin(deps.config)] },
		async (context) => {
			const userAgent = context.req.valid("header")["user-agent"];
			const session = await createSession(deps.db, {
				userId: context.req.valid("json").userId,
				now: deps.now(),
				...(userAgent === undefined ? {} : { userAgent }),
			});
			setCookie(
				context,
				SESSION_COOKIE,
				session.token,
				sessionCookieAttributes(deps.config.appEnv),
			);
			return context.body(null, 204);
		},
	);
}
