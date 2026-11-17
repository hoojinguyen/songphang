import { createRoute, type OpenAPIHono } from "@hono/zod-openapi";
import { FeaturesResponse } from "@songphang/contract";
import type { AppEnv } from "../app.js";

export function registerFeatureRoute(app: OpenAPIHono<AppEnv>): void {
	app.openapi(
		createRoute({
			method: "get",
			path: "/api/v1/features",
			responses: {
				200: {
					description: "Optional service capabilities",
					content: { "application/json": { schema: FeaturesResponse } },
				},
			},
		}),
		(context) =>
			context.json(
				FeaturesResponse.parse({
					receiptReading: false,
					sentenceAi: false,
					telegram: false,
					push: false,
					appleSignIn: false,
					errorAlerts: false,
				}),
				200,
			),
	);
}
