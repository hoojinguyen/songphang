import { type OpenAPIHono, z } from "@hono/zod-openapi";
import { UnsubscribeRequest } from "@songphang/contract";
import type { Context } from "hono";
import type { AppDeps, AppEnv } from "../app.js";
import { socketIp } from "../auth/account-limits.js";
import { AppError } from "../errors.js";
import { unsubscribeNotifications } from "../services/notifications.js";

const MAX_BODY_CHARS = 4096;
const JsonTokenBody = z.object({ token: z.unknown() });

function notFound(): AppError {
	return new AppError(404, "NOT_FOUND", "Resource not found");
}

async function extractUnsubscribeToken(
	context: Context<AppEnv>,
): Promise<string> {
	const queryToken = context.req.query("token");
	const rawText = await context.req.text();
	if (rawText.length > MAX_BODY_CHARS) {
		throw notFound();
	}
	const contentType =
		context.req.header("Content-Type")?.split(";")[0]?.trim().toLowerCase() ??
		"";
	let bodyToken: unknown;

	if (contentType === "application/json") {
		let parsedJson: unknown;
		try {
			parsedJson = JSON.parse(rawText);
		} catch {
			throw notFound();
		}
		const obj = JsonTokenBody.safeParse(parsedJson);
		if (!obj.success) throw notFound();
		bodyToken = obj.data.token;
	} else if (contentType === "application/x-www-form-urlencoded") {
		const params = new URLSearchParams(rawText);
		const listUnsub = params.get("List-Unsubscribe");
		if (listUnsub !== null && listUnsub !== "One-Click") {
			throw notFound();
		}
		bodyToken = params.get("token") ?? undefined;
	} else if (rawText.trim().length > 0) {
		throw notFound();
	}

	if (
		queryToken !== undefined &&
		bodyToken !== undefined &&
		queryToken !== bodyToken
	) {
		throw notFound();
	}

	const parsed = UnsubscribeRequest.safeParse({
		token: queryToken ?? bodyToken,
	});
	if (!parsed.success) {
		throw notFound();
	}
	return parsed.data.token;
}

export function registerUnsubscribeRoutes(
	app: OpenAPIHono<AppEnv>,
	deps: AppDeps,
): void {
	const limit = deps.rateLimiter.limit({
		name: "unsubscribe",
		max: 30,
		windowMs: 60_000,
		key: (context) => socketIp(context),
	});

	// Mail providers send RFC 8058 POSTs without cookies or browser Origin;
	// requests are authorized solely by the 256-bit unsubscribe token.
	app.post("/api/v1/notifications/unsubscribe", limit, async (context) => {
		const token = await extractUnsubscribeToken(context);
		await unsubscribeNotifications(deps, token);
		return context.body(null, 204);
	});
}
