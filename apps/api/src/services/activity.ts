import { z } from "@hono/zod-openapi";
import { type ActivityQuery, ActivityResponse } from "@songphang/contract";
import { listActivityRows } from "@songphang/db";
import type { AppDeps } from "../app.js";
import { AppError } from "../errors.js";

const Cursor = z.object({ createdAt: z.iso.datetime(), id: z.uuid() });
function decode(value: string | undefined) {
	if (value === undefined) return null;
	try {
		if (!/^[A-Za-z0-9_-]+$/.test(value)) throw new Error("Invalid cursor");
		return Cursor.parse(
			JSON.parse(Buffer.from(value, "base64url").toString("utf8")),
		);
	} catch {
		throw new AppError(400, "VALIDATION_FAILED", "Invalid cursor");
	}
}
export async function listActivity(
	deps: AppDeps,
	groupId: string,
	query: ActivityQuery,
) {
	const rows = await listActivityRows(deps.db, {
		groupId,
		limit: query.limit + 1,
		cursor: decode(query.cursor),
	});
	const page = rows.slice(0, query.limit);
	const last = page.at(-1);
	return ActivityResponse.parse({
		activity: page.map((row) => ({
			...row,
			actor: row.actorId
				? { userId: row.actorId, name: row.actorName, memberId: row.memberId }
				: null,
			createdAt: row.createdAt.toISOString(),
		})),
		nextCursor:
			rows.length > query.limit && last
				? Buffer.from(
						JSON.stringify({
							createdAt: last.createdAt.toISOString(),
							id: last.id,
						}),
					).toString("base64url")
				: null,
	});
}
