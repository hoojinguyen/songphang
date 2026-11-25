"use client";
import {
	ConfirmSettlementResponse,
	type CreateSettlementRequest,
	SettlementRequestResponse,
	SettlementRequestsResponse,
} from "@songphang/contract";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import type { z } from "zod";
import { type ApiError, apiFetch } from "./api";
import { jsonRequest } from "./request";

type SettlementRequestsList = z.infer<
	typeof SettlementRequestsResponse
>["requests"];
type SettlementRequestItem = z.infer<
	typeof SettlementRequestResponse
>["request"];

async function invalidateAfterSettlement(
	client: ReturnType<typeof useQueryClient>,
	groupId: string,
	action?: "confirm" | "reject" | "cancel",
) {
	await Promise.all([
		client.invalidateQueries({ queryKey: ["group", groupId, "balances"] }),
		client.invalidateQueries({
			queryKey: ["group", groupId, "settlementRequests"],
		}),
		client.invalidateQueries({
			queryKey: ["group", groupId, "settlement-vault"],
		}),
		client.invalidateQueries({ queryKey: ["group", groupId, "breakdowns"] }),
		...(action === "confirm"
			? [
					client.invalidateQueries({
						queryKey: ["group", groupId],
						exact: true,
					}),
					client.invalidateQueries({
						queryKey: ["group", groupId, "transactions"],
					}),
					client.invalidateQueries({
						queryKey: ["group", groupId, "settlementCycles"],
					}),
					client.invalidateQueries({
						queryKey: ["group", groupId, "activity"],
					}),
					client.invalidateQueries({ queryKey: ["groups"] }),
				]
			: []),
	]);
}

export function usePendingSettlementRequests(groupId: string) {
	return useQuery<SettlementRequestsList, ApiError>({
		queryKey: ["group", groupId, "settlementRequests"],
		queryFn: async () =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/settlement-requests?status=pending`,
					SettlementRequestsResponse,
				)
			).requests,
	});
}

export function useCreateSettlementRequest(groupId: string) {
	const client = useQueryClient();
	return useMutation<
		SettlementRequestItem,
		ApiError,
		{ request: CreateSettlementRequest; key: string }
	>({
		mutationFn: async ({ request, key }) =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/settlement-requests`,
					SettlementRequestResponse,
					jsonRequest("POST", request, key),
				)
			).request,
		onSuccess: () => invalidateAfterSettlement(client, groupId),
	});
}

export function useResolveSettlementRequest(groupId: string) {
	const client = useQueryClient();
	return useMutation<
		SettlementRequestItem,
		ApiError,
		{ id: string; action: "confirm" | "reject" | "cancel" }
	>({
		mutationFn: async ({ id, action }) => {
			const path = `/groups/${encodeURIComponent(groupId)}/settlement-requests/${encodeURIComponent(id)}/${action}`;
			if (action === "confirm") {
				return (
					await apiFetch(path, ConfirmSettlementResponse, jsonRequest("POST"))
				).request;
			}
			return (
				await apiFetch(path, SettlementRequestResponse, jsonRequest("POST"))
			).request;
		},
		onSuccess: (_data, { action }) =>
			invalidateAfterSettlement(client, groupId, action),
	});
}
