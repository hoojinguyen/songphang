"use client";
import {
	type CreateTransactionRequest,
	type TransactionDto,
	TransactionResponse,
} from "@songphang/contract";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { type ApiError, apiFetch, apiSend } from "./api";
import { jsonRequest } from "./request";
export function transactionRequestOf(
	t: TransactionDto,
): CreateTransactionRequest {
	return t.type === "transfer"
		? transferRequest(t)
		: {
				type: t.type,
				description: t.description,
				amount: t.amount,
				occurredAt: t.occurredAt,
				category: t.category,
				payers: t.payers,
				split: t.split,
			};
}
function transferRequest(t: TransactionDto): CreateTransactionRequest {
	return {
		type: "transfer",
		amount: t.amount,
		description: t.description,
		occurredAt: t.occurredAt,
		fromMemberId: t.payers[0]?.memberId ?? "",
		toMemberId: t.shares[0]?.memberId ?? "",
	};
}
export function useTransaction(groupId: string, id: string) {
	return useQuery<TransactionDto, ApiError>({
		queryKey: ["group", groupId, "transactions", id],
		queryFn: async () =>
			(
				await apiFetch(
					`/groups/${groupId}/transactions/${encodeURIComponent(id)}`,
					TransactionResponse,
				)
			).transaction,
	});
}
function useRefresh(groupId: string) {
	const client = useQueryClient();
	return () => {
		void client.invalidateQueries({ queryKey: ["group", groupId] });
		void client.invalidateQueries({ queryKey: ["groups"] });
	};
}
export function useUpdateTransaction(
	groupId: string,
	id: string,
	version: number,
) {
	const refresh = useRefresh(groupId);
	return useMutation<
		{ transaction: TransactionDto },
		ApiError,
		{ request: CreateTransactionRequest; key: string }
	>({
		mutationFn: ({ request }) =>
			apiFetch(
				`/groups/${groupId}/transactions/${id}`,
				TransactionResponse,
				jsonRequest("PATCH", { ...request, version }),
			),
		onSuccess: refresh,
	});
}
export function useDeleteTransaction(groupId: string) {
	const refresh = useRefresh(groupId);
	return useMutation<void, ApiError, string>({
		mutationFn: (id) =>
			apiSend(`/groups/${groupId}/transactions/${id}`, jsonRequest("DELETE")),
		onSuccess: refresh,
	});
}
export function useRestoreTransaction(groupId: string) {
	const refresh = useRefresh(groupId);
	return useMutation<{ transaction: TransactionDto }, ApiError, string>({
		mutationFn: (id) =>
			apiFetch(
				`/groups/${groupId}/transactions/${id}/restore`,
				TransactionResponse,
				jsonRequest("POST"),
			),
		onSuccess: refresh,
	});
}
