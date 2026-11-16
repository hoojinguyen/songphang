"use client";
import { ActivityResponse } from "@songphang/contract";
import { useInfiniteQuery } from "@tanstack/react-query";
import { type ApiError, apiFetch } from "./api";
export function useActivity(groupId: string) {
	return useInfiniteQuery<
		import("zod").z.infer<typeof ActivityResponse>,
		ApiError
	>({
		queryKey: ["group", groupId, "activity"],
		initialPageParam: null as string | null,
		queryFn: ({ pageParam }) =>
			apiFetch(
				`/groups/${groupId}/activity?limit=50${typeof pageParam === "string" ? `&cursor=${encodeURIComponent(pageParam)}` : ""}`,
				ActivityResponse,
			),
		getNextPageParam: (page) => page.nextCursor,
	});
}
