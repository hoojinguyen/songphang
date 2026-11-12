"use client";
import {
	CreateTransactionRequest,
	PreviewTransactionResponse,
	TransactionResponse,
	TransactionsResponse,
} from "@songphang/contract";
import {
	type InfiniteData,
	keepPreviousData,
	useInfiniteQuery,
	useMutation,
	useQuery,
	useQueryClient,
} from "@tanstack/react-query";
import { useEffect, useState } from "react";
import type { z } from "zod";
import { vi } from "../messages/vi";
import { type ApiError, apiFetch } from "./api";
import { jsonRequest } from "./request";

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

export function useCreateTransaction(groupId: string) {
	const client = useQueryClient();
	return useMutation<
		z.infer<typeof TransactionResponse>,
		ApiError,
		{ request: CreateTransactionRequest; key: string }
	>({
		mutationFn: ({ request, key }) =>
			apiFetch(
				`/groups/${encodeURIComponent(groupId)}/transactions`,
				TransactionResponse,
				jsonRequest("POST", request, key),
			),
		onSuccess: async () => {
			await Promise.all([
				client.invalidateQueries({
					queryKey: ["group", groupId, "transactions"],
				}),
				client.invalidateQueries({ queryKey: ["group", groupId, "balances"] }),
				client.invalidateQueries({ queryKey: ["groups"] }),
			]);
		},
	});
}
export function usePreviewShares(
	groupId: string,
	request: CreateTransactionRequest | null,
) {
	const serialized = request === null ? null : JSON.stringify(request);
	const [debounced, setDebounced] = useState<CreateTransactionRequest | null>(
		null,
	);
	useEffect(() => {
		const timer = setTimeout(
			() =>
				setDebounced(
					serialized === null
						? null
						: CreateTransactionRequest.parse(JSON.parse(serialized)),
				),
			250,
		);
		return () => clearTimeout(timer);
	}, [serialized]);
	return useQuery<z.infer<typeof PreviewTransactionResponse>, ApiError>({
		queryKey: ["group", groupId, "preview", debounced],
		enabled: request !== null && debounced !== null,
		queryFn: () =>
			apiFetch(
				`/groups/${encodeURIComponent(groupId)}/transactions/preview`,
				PreviewTransactionResponse,
				jsonRequest("POST", debounced),
			),
		placeholderData: keepPreviousData,
	});
}
