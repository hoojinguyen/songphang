"use client";
import { TransactionsResponse } from "@songphang/contract";
import { type InfiniteData, useInfiniteQuery } from "@tanstack/react-query";
import type { z } from "zod";
import { vi } from "../messages/vi";
import { type ApiError, apiFetch } from "./api";

type TransactionsPage = z.infer<typeof TransactionsResponse>;
export function useTransactions(groupId: string) {
	return useInfiniteQuery<
		TransactionsPage,
		ApiError,
		InfiniteData<TransactionsPage>,
		readonly ["group", string, "transactions"],
		string | null
	>({
		queryKey: ["group", groupId, "transactions"],
		initialPageParam: null,
		queryFn: ({ pageParam }) =>
			apiFetch(
				`/groups/${encodeURIComponent(groupId)}/transactions?limit=50${pageParam === null ? "" : `&cursor=${encodeURIComponent(pageParam)}`}`,
				TransactionsResponse,
			),
		getNextPageParam: (page) => page.nextCursor,
	});
}
export function dayLabel(occurredAt: string, now: Date): string {
	const date = new Date(occurredAt);
	const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
	const yesterday = new Date(
		now.getFullYear(),
		now.getMonth(),
		now.getDate() - 1,
	);
	const day = new Date(
		date.getFullYear(),
		date.getMonth(),
		date.getDate(),
	).getTime();
	if (day === today.getTime()) return vi.feed.today;
	if (day === yesterday.getTime()) return vi.feed.yesterday;
	return `${String(date.getDate()).padStart(2, "0")}/${String(date.getMonth() + 1).padStart(2, "0")}/${date.getFullYear()}`;
}
