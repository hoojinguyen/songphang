"use client";
import {
	CalendarDate,
	CreateTransactionRequest,
	PreviewExtrasRequest,
	PreviewExtrasResponse,
	PreviewTransactionRequest,
	PreviewTransactionResponse,
	TransactionCategory,
	TransactionResponse,
	TransactionsResponse,
} from "@songphang/contract";
import { isWithinFiveYears } from "@songphang/core";
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

export type TransactionFilters = {
	q?: string | undefined;
	memberId?: string | undefined;
	category?: z.infer<typeof TransactionCategory> | undefined;
	categoryId?: string | undefined;
	uncategorized?: true | undefined;
	spendingOnly?: true | undefined;
	type?: "expense" | "transfer" | "income" | undefined;
	from?: string | undefined;
	to?: string | undefined;
	cycleId?: "current" | string | undefined;
};

export function hasActiveFilters(filters: TransactionFilters): boolean {
	return Boolean(
		filters.q ||
			filters.memberId ||
			filters.category ||
			filters.categoryId ||
			filters.uncategorized ||
			filters.spendingOnly ||
			filters.type ||
			filters.from ||
			filters.to,
	);
}

export function readTransactionFilters(params: {
	get: (key: string) => string | null;
}): TransactionFilters {
	const qRaw = params.get("q")?.trim() ?? "";
	const q = qRaw.length > 0 && qRaw.length <= 100 ? qRaw : undefined;
	const memberParsed = CalendarUuid.safeParse(params.get("member"));
	const categoryParsed = TransactionCategory.safeParse(params.get("category"));
	const categoryIdParsed = CalendarUuid.safeParse(params.get("categoryId"));
	const uncategorized =
		!categoryParsed.success &&
		!categoryIdParsed.success &&
		params.get("uncategorized") === "true"
			? (true as const)
			: undefined;
	const typeParsed = TypeFilter.safeParse(params.get("type"));
	const fromParsed = CalendarDate.safeParse(params.get("from"));
	const toParsed = CalendarDate.safeParse(params.get("to"));
	let from = fromParsed.success ? fromParsed.data : undefined;
	let to = toParsed.success ? toParsed.data : undefined;
	if (from && to && !isWithinFiveYears(from, to)) {
		from = undefined;
		to = undefined;
	}
	const rawCycleId = params.get("cycleId");
	const cycleId =
		rawCycleId === "current"
			? "current"
			: CalendarUuid.safeParse(rawCycleId).success
				? (rawCycleId ?? undefined)
				: undefined;
	return {
		...(q ? { q } : {}),
		...(memberParsed.success ? { memberId: memberParsed.data } : {}),
		...(categoryParsed.success ? { category: categoryParsed.data } : {}),
		...(categoryIdParsed.success ? { categoryId: categoryIdParsed.data } : {}),
		...(uncategorized ? { uncategorized } : {}),
		...(typeParsed.success ? { type: typeParsed.data } : {}),
		...(params.get("spendingOnly") === "true" &&
		(!typeParsed.success || typeParsed.data !== "transfer")
			? { spendingOnly: true as const }
			: {}),
		...(from ? { from } : {}),
		...(to ? { to } : {}),
		...(cycleId ? { cycleId } : {}),
	};
}

export function buildFilterQueryString(filters: TransactionFilters): string {
	const params = new URLSearchParams();
	if (filters.q) params.set("q", filters.q);
	if (filters.memberId) params.set("member", filters.memberId);
	if (filters.category) params.set("category", filters.category);
	if (filters.categoryId) params.set("categoryId", filters.categoryId);
	if (filters.uncategorized) params.set("uncategorized", "true");
	if (filters.spendingOnly) params.set("spendingOnly", "true");
	if (filters.type) params.set("type", filters.type);
	if (filters.from) params.set("from", filters.from);
	if (filters.to) params.set("to", filters.to);
	if (filters.cycleId) params.set("cycleId", filters.cycleId);
	return params.toString();
}

const CalendarUuid =
	CreateTransactionRequest.options[0].shape.payers.element.shape.memberId;
const TypeFilter = TransactionResponse.shape.transaction.shape.type;

type TransactionsPage = z.infer<typeof TransactionsResponse>;
export function useTransactions(
	groupId: string,
	filters: TransactionFilters = {},
) {
	return useInfiniteQuery<
		TransactionsPage,
		ApiError,
		InfiniteData<TransactionsPage>,
		readonly ["group", string, "transactions", TransactionFilters],
		string | null
	>({
		queryKey: ["group", groupId, "transactions", filters],
		initialPageParam: null,
		queryFn: ({ pageParam }) => {
			const params = new URLSearchParams({ limit: "50" });
			if (pageParam !== null) params.set("cursor", pageParam);
			if (filters.q) params.set("q", filters.q);
			if (filters.memberId) params.set("memberId", filters.memberId);
			if (filters.category) params.set("category", filters.category);
			if (filters.categoryId) params.set("categoryId", filters.categoryId);
			if (filters.uncategorized) params.set("uncategorized", "true");
			if (filters.spendingOnly) params.set("spendingOnly", "true");
			if (filters.type) params.set("type", filters.type);
			if (filters.from) params.set("from", filters.from);
			if (filters.to) params.set("to", filters.to);
			if (filters.cycleId) params.set("cycleId", filters.cycleId);
			return apiFetch(
				`/groups/${encodeURIComponent(groupId)}/transactions?${params.toString()}`,
				TransactionsResponse,
			);
		},
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
				client.invalidateQueries({
					queryKey: ["group", groupId, "breakdowns"],
				}),
				client.invalidateQueries({
					queryKey: ["group", groupId, "settlement-vault"],
				}),
				client.invalidateQueries({
					queryKey: ["group", groupId, "settlementCycles"],
				}),
				client.invalidateQueries({ queryKey: ["group", groupId, "budget"] }),
				client.invalidateQueries({ queryKey: ["group", groupId, "stats"] }),
				client.invalidateQueries({ queryKey: ["groups"] }),
			]);
		},
	});
}
export function usePreviewShares(
	groupId: string,
	request: CreateTransactionRequest | null,
	transactionId?: string,
) {
	const payload =
		request === null || request.type === "transfer"
			? null
			: transactionId
				? { ...request, transactionId }
				: request;
	const serialized = payload === null ? null : JSON.stringify(payload);
	const [debounced, setDebounced] = useState<PreviewTransactionRequest | null>(
		null,
	);
	useEffect(() => {
		const timer = setTimeout(
			() =>
				setDebounced(
					serialized === null
						? null
						: PreviewTransactionRequest.parse(JSON.parse(serialized)),
				),
			250,
		);
		return () => clearTimeout(timer);
	}, [serialized]);
	const query = useQuery<z.infer<typeof PreviewTransactionResponse>, ApiError>({
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
	return {
		...query,
		current:
			serialized === JSON.stringify(debounced) &&
			!query.isFetching &&
			!query.isPlaceholderData,
	};
}

export function usePreviewExtras(
	groupId: string,
	request: PreviewExtrasRequest | null,
) {
	const serialized = request === null ? null : JSON.stringify(request);
	const [debounced, setDebounced] = useState<PreviewExtrasRequest | null>(null);
	useEffect(() => {
		const timer = setTimeout(() => {
			if (serialized === null) {
				setDebounced(null);
				return;
			}
			const parsed = PreviewExtrasRequest.safeParse(JSON.parse(serialized));
			setDebounced(parsed.success ? parsed.data : null);
		}, 300);
		return () => clearTimeout(timer);
	}, [serialized]);

	const query = useQuery<z.infer<typeof PreviewExtrasResponse>, ApiError>({
		queryKey: ["group", groupId, "extrasPreview", debounced],
		enabled: request !== null && debounced !== null,
		queryFn: ({ signal }) =>
			apiFetch(
				`/groups/${encodeURIComponent(groupId)}/transactions/extras/preview`,
				PreviewExtrasResponse,
				{ ...jsonRequest("POST", debounced), signal },
			),
		placeholderData: keepPreviousData,
	});

	return {
		...query,
		current:
			serialized === JSON.stringify(debounced) &&
			!query.isFetching &&
			!query.isPlaceholderData &&
			query.isSuccess &&
			!query.isError,
	};
}

export {
	useDeleteTransaction,
	useRestoreTransaction,
	useTransaction,
	useUpdateTransaction,
} from "./transaction-changes";
