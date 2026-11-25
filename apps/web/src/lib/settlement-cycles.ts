"use client";
import {
	SettlementCycleResponse,
	SettlementCyclesResponse,
} from "@songphang/contract";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { type ApiError, apiFetch, apiSend } from "./api";
import { jsonRequest } from "./request";

async function invalidateAfterCycleChange(
	client: ReturnType<typeof useQueryClient>,
	groupId: string,
) {
	await Promise.all([
		client.invalidateQueries({
			queryKey: ["group", groupId, "settlementCycles"],
		}),
		client.invalidateQueries({
			queryKey: ["group", groupId, "transactions"],
		}),
		client.invalidateQueries({ queryKey: ["group", groupId, "balances"] }),
		client.invalidateQueries({ queryKey: ["group", groupId, "breakdowns"] }),
		client.invalidateQueries({
			queryKey: ["group", groupId, "settlement-vault"],
		}),
		client.invalidateQueries({ queryKey: ["group", groupId, "activity"] }),
		client.invalidateQueries({ queryKey: ["group", groupId], exact: true }),
	]);
}

export function useSettlementCycles(groupId: string) {
	return useQuery<SettlementCyclesResponse, ApiError>({
		queryKey: ["group", groupId, "settlementCycles"],
		queryFn: () =>
			apiFetch(
				`/groups/${encodeURIComponent(groupId)}/settlement-cycles`,
				SettlementCyclesResponse,
			),
	});
}

export function useCloseSettlementCycle(groupId: string) {
	const client = useQueryClient();
	return useMutation<
		SettlementCycleResponse,
		ApiError,
		{ title?: string; key: string }
	>({
		mutationFn: ({ title, key }) => {
			const trimmed = title?.trim();
			return apiFetch(
				`/groups/${encodeURIComponent(groupId)}/settlement-cycles`,
				SettlementCycleResponse,
				jsonRequest("POST", trimmed ? { title: trimmed } : {}, key),
			);
		},
		onSuccess: () => invalidateAfterCycleChange(client, groupId),
	});
}

export function useReopenSettlementCycle(groupId: string) {
	const client = useQueryClient();
	return useMutation<void, ApiError, string>({
		mutationFn: (cycleId) =>
			apiSend(
				`/groups/${encodeURIComponent(groupId)}/settlement-cycles/${encodeURIComponent(cycleId)}`,
				jsonRequest("DELETE"),
			),
		onSuccess: () => invalidateAfterCycleChange(client, groupId),
	});
}
