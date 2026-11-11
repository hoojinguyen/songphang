import { z } from "@hono/zod-openapi";

export const HealthResponse = z
	.object({
		status: z.enum(["ok", "degraded"]),
		db: z.enum(["ok", "down"]),
	})
	.openapi("HealthResponse");
export type HealthResponse = z.infer<typeof HealthResponse>;
