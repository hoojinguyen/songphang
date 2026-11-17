import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import { streamSSE } from "hono/streaming";
import type { AppDeps, AppEnv } from "../app.js";
import { hasGroupSession } from "../auth/event-access.js";
import { requireGroupRole } from "../auth/group-access.js";
import { requireUser } from "../auth/middleware.js";
import { hashSessionToken } from "../auth/sessions.js";

const route = createRoute({
	method: "get",
	path: "/api/v1/groups/{groupId}/events",
	request: { params: z.object({ groupId: z.uuid() }) },
	responses: {
		200: {
			description: "Group invalidation events",
			content: { "text/event-stream": { schema: z.string() } },
		},
	},
});
export function registerEventRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
	app.openapi(
		{
			...route,
			middleware: [requireUser(deps), requireGroupRole(deps, "viewer")],
		},
		(c) => {
			const response = streamSSE(c, async (stream) => {
				let isStopped = false;
				let finish = () => {};
				const disconnected = new Promise<void>((resolve) => {
					finish = () => {
						isStopped = true;
						resolve();
					};
				});
				const stop = () => {
					finish();
					stream.abort();
				};
				const stopOnError = () => {
					if (!isStopped) stop();
				};
				const access = {
					groupId: c.var.groupAccess.groupId,
					token: c.var.sessionToken,
				};
				const canWrite = async () => {
					if (isStopped) return false;
					const hasAccess = await hasGroupSession(deps, access);
					if (isStopped) return false;
					if (!hasAccess) stop();
					return hasAccess;
				};
				let pending = Promise.resolve();
				const unsubscribe = deps.events.subscribe(
					{
						groupId: c.var.groupAccess.groupId,
						userId: c.var.user.id,
						tokenHash: hashSessionToken(c.var.sessionToken),
					},
					(event) => {
						if (event.type === "revoked") {
							stop();
							return;
						}
						if (isStopped) return;
						if (event.type === "removed") {
							isStopped = true;
							void stream
								.writeSSE({ event: "removed", data: "{}" })
								.then(finish, stop);
							return;
						}
						pending = pending
							.then(async () => {
								if (!(await canWrite()) || isStopped) return;
								await stream.writeSSE({
									event: event.type,
									data: JSON.stringify({ resources: event.resources }),
								});
							})
							.catch(stopOnError);
					},
				);
				stream.onAbort(stop);
				const timer = setInterval(() => {
					pending = pending
						.then(async () => {
							if (!(await canWrite()) || isStopped) return;
							await stream.write(": keep-alive\n\n");
						})
						.catch(stopOnError);
				}, 25_000);
				try {
					pending = pending
						.then(async () => {
							if (!(await canWrite()) || isStopped) return;
							await stream.write(": connected\n\n");
						})
						.catch(stopOnError);
					await disconnected;
				} finally {
					finish();
					clearInterval(timer);
					unsubscribe();
				}
			});
			response.headers.set("Cache-Control", "no-cache, no-transform");
			response.headers.set("X-Accel-Buffering", "no");
			return response;
		},
	);
}
