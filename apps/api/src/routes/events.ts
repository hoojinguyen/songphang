import { createRoute, type OpenAPIHono, z } from "@hono/zod-openapi";
import { streamSSE } from "hono/streaming";
import type { AppDeps, AppEnv } from "../app.js";
import { requireGroupRole } from "../auth/group-access.js";
import { requireUser } from "../auth/middleware.js";

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
				let finish = () => {};
				const disconnected = new Promise<void>((resolve) => {
					finish = resolve;
				});
				let pending = Promise.resolve();
				const unsubscribe = deps.events.subscribe(
					c.var.groupAccess.groupId,
					c.var.user.id,
					(event) => {
						pending = pending
							.then(async () => {
								await stream.writeSSE({
									event: event.type,
									data: JSON.stringify(
										event.type === "changed"
											? { resources: event.resources }
											: {},
									),
								});
								if (event.type === "removed") finish();
							})
							.catch(() => finish());
					},
				);
				stream.onAbort(finish);
				const timer = setInterval(() => {
					pending = pending
						.then(async () => {
							await stream.write(": keep-alive\n\n");
						})
						.catch(() => finish());
				}, 25_000);
				try {
					await stream.write(": connected\n\n");
					await disconnected;
					await pending;
				} finally {
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
