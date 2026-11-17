"use client";
import {
	type BudgetDto,
	BudgetResponse,
	type PutBudgetRequest,
} from "@songphang/contract";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { type ApiError, apiFetch, apiSend } from "./api";
import { jsonRequest } from "./request";

export function useBudget(groupId: string) {
	return useQuery<BudgetDto | null, ApiError>({
		queryKey: ["group", groupId, "budget"],
		queryFn: async () =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/budget`,
					BudgetResponse,
				)
			).budget,
	});
}

async function invalidateBudget(
	client: ReturnType<typeof useQueryClient>,
	groupId: string,
) {
	await Promise.all([
		client.invalidateQueries({ queryKey: ["group", groupId, "budget"] }),
		client.invalidateQueries({ queryKey: ["group", groupId, "activity"] }),
	]);
}

export function usePutBudget(groupId: string) {
	const client = useQueryClient();
	return useMutation<BudgetDto | null, ApiError, PutBudgetRequest>({
		mutationFn: async (request) =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/budget`,
					BudgetResponse,
					jsonRequest("PUT", request),
				)
			).budget,
		onSuccess: () => invalidateBudget(client, groupId),
	});
}

export function useDeleteBudget(groupId: string) {
	const client = useQueryClient();
	return useMutation<void, ApiError>({
		mutationFn: () =>
			apiSend(
				`/groups/${encodeURIComponent(groupId)}/budget`,
				jsonRequest("DELETE"),
			),
		onSuccess: () => invalidateBudget(client, groupId),
	});
}
