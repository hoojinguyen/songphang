"use client";
import {
	type SettlementVaultFilter,
	SettlementVaultResponse,
} from "@songphang/contract";
import { type InfiniteData, useInfiniteQuery } from "@tanstack/react-query";
import { type ApiError, apiFetch } from "./api";

export function useSettlementVault(
	groupId: string,
	options: {
		filter?: SettlementVaultFilter;
		cycleId?: "current" | string;
	} = {},
) {
	const filter = options.filter ?? "all";
	const cycleId = options.cycleId;
	return useInfiniteQuery<
		SettlementVaultResponse,
		ApiError,
		InfiniteData<SettlementVaultResponse>,
		readonly [
			"group",
			string,
			"settlement-vault",
			SettlementVaultFilter,
			string | null,
		],
		string | null
	>({
		queryKey: ["group", groupId, "settlement-vault", filter, cycleId ?? null],
		initialPageParam: null,
		queryFn: ({ pageParam }) => {
			const params = new URLSearchParams({ filter, limit: "50" });
			if (cycleId) params.set("cycleId", cycleId);
			if (pageParam !== null) params.set("cursor", pageParam);
			return apiFetch(
				`/groups/${encodeURIComponent(groupId)}/settlement-vault?${params.toString()}`,
				SettlementVaultResponse,
			);
		},
		getNextPageParam: (page) => page.nextCursor,
	});
}
