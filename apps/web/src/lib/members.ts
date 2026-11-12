"use client";
import { type MemberDto, MembersResponse } from "@songphang/contract";
import { useQuery } from "@tanstack/react-query";
import { type ApiError, apiFetch } from "./api";
export function useMembers(groupId: string) {
	return useQuery<MemberDto[], ApiError>({
		queryKey: ["group", groupId, "members"],
		queryFn: async () =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/members`,
					MembersResponse,
				)
			).members,
	});
}
