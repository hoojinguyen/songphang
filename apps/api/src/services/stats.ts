import { type StatsQuery, StatsResponse } from "@songphang/contract";
import {
	APP_TIME_ZONE,
	bucketFor,
	localDateRangeToUtc,
	toVietnamDate,
} from "@songphang/core";
import {
	findCountedDateBounds,
	sumByBucket,
	sumByCategory,
	sumByMember,
} from "@songphang/db";
import type { AppDeps } from "../app.js";

function resolveBounds(input: {
	query: StatsQuery;
	firstDate: string | null;
	lastDate: string | null;
	today: string;
}) {
	const from =
		input.query.from ?? input.firstDate ?? input.query.to ?? input.today;
	const to =
		input.query.to ?? input.lastDate ?? input.query.from ?? input.today;
	if (from > to) {
		return input.query.from !== undefined
			? { from: input.query.from, to: input.query.from }
			: { from: to, to };
	}
	return { from, to };
}

export async function getGroupStats(
	deps: AppDeps,
	groupId: string,
	query: StatsQuery,
) {
	return deps.db.transaction(
		async (executor) => {
			const bounds =
				query.from === undefined || query.to === undefined
					? await findCountedDateBounds(executor, groupId, APP_TIME_ZONE)
					: { firstDate: null, lastDate: null };
			const { from, to } = resolveBounds({
				query,
				firstDate: bounds.firstDate,
				lastDate: bounds.lastDate,
				today: toVietnamDate(deps.now()),
			});
			const range = localDateRangeToUtc(query.from, query.to);
			const bucket = bucketFor(from, to);
			const [byCategory, byMember, bucketResult] = await Promise.all([
				sumByCategory(executor, groupId, range),
				sumByMember(executor, groupId, range),
				sumByBucket(executor, {
					groupId,
					bucket,
					timeZone: APP_TIME_ZONE,
					...range,
				}),
			]);
			return StatsResponse.parse({
				from,
				to,
				bucket,
				total: bucketResult.total,
				byCategory,
				byMember,
				byBucket: bucketResult.byBucket,
			});
		},
		{ isolationLevel: "repeatable read", accessMode: "read only" },
	);
}
