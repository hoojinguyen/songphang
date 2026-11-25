"use client";
import {
	OverviewResponse,
	PersonalTransactionsResponse,
} from "@songphang/contract";
import {
	type InfiniteData,
	useInfiniteQuery,
	useQuery,
	useQueryClient,
} from "@tanstack/react-query";
import { type ApiError, apiFetch } from "./api";

export function useOverview() {
	return useQuery<OverviewResponse, ApiError>({
		queryKey: ["me", "overview"],
		queryFn: () => apiFetch("/me/overview", OverviewResponse),
		refetchOnWindowFocus: true,
	});
}

export function useInvalidateOverview() {
	const client = useQueryClient();
	return () => client.invalidateQueries({ queryKey: ["me", "overview"] });
}

type PersonalTransactionsFilters = {
	type?: "expense" | "transfer" | "income" | undefined;
	groupId?: string | undefined;
	q?: string | undefined;
};

export function usePersonalTransactions(
	filters: PersonalTransactionsFilters = {},
) {
	return useInfiniteQuery<
		PersonalTransactionsResponse,
		ApiError,
		InfiniteData<PersonalTransactionsResponse>,
		readonly ["me", "transactions", PersonalTransactionsFilters],
		string | null
	>({
		queryKey: ["me", "transactions", filters],
		initialPageParam: null,
		queryFn: ({ pageParam }) => {
			const params = new URLSearchParams({ limit: "20" });
			if (pageParam !== null) params.set("cursor", pageParam);
			if (filters.type) params.set("type", filters.type);
			if (filters.groupId) params.set("groupId", filters.groupId);
			if (filters.q) params.set("q", filters.q);
			return apiFetch(
				`/me/transactions?${params.toString()}`,
				PersonalTransactionsResponse,
			);
		},
		getNextPageParam: (page) => page.nextCursor,
		refetchOnWindowFocus: true,
	});
}
