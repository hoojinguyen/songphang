"use client";
import { MemberBreakdownsResponse } from "@songphang/contract";
import { useQuery } from "@tanstack/react-query";
import { type ApiError, apiFetch } from "./api";

export function useMemberBreakdowns(
	groupId: string,
	cycleId: "auto" | "current" | string = "auto",
	enabled = true,
) {
	return useQuery<MemberBreakdownsResponse, ApiError>({
		queryKey: ["group", groupId, "breakdowns", cycleId],
		enabled,
		queryFn: () =>
			apiFetch(
				`/groups/${encodeURIComponent(groupId)}/balances/breakdowns?cycleId=${encodeURIComponent(cycleId)}`,
				MemberBreakdownsResponse,
			),
	});
}
