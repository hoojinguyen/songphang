"use client";
import { StatsResponse } from "@songphang/contract";
import { useQuery } from "@tanstack/react-query";
import { type ApiError, apiFetch } from "./api";

export function useGroupStats(
	groupId: string,
	range: { from?: string; to?: string },
) {
	const params = new URLSearchParams();
	if (range.from) params.set("from", range.from);
	if (range.to) params.set("to", range.to);
	const qs = params.toString();
	return useQuery<StatsResponse, ApiError>({
		queryKey: ["group", groupId, "stats", range.from ?? null, range.to ?? null],
		queryFn: () =>
			apiFetch(
				`/groups/${encodeURIComponent(groupId)}/stats${qs ? `?${qs}` : ""}`,
				StatsResponse,
			),
	});
}
