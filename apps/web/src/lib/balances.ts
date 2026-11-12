"use client";
import { BalancesResponse } from "@songphang/contract";
import { useQuery } from "@tanstack/react-query";
import { type ApiError, apiFetch } from "./api";
export function useBalances(groupId: string) {
	return useQuery<BalancesResponse, ApiError>({
		queryKey: ["group", groupId, "balances"],
		queryFn: () =>
			apiFetch(
				`/groups/${encodeURIComponent(groupId)}/balances`,
				BalancesResponse,
			),
	});
}
