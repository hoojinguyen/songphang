"use client";
import {
	GuestGroupViewResponse,
	type GuestLinkDto,
	GuestLinkResponse,
} from "@songphang/contract";
import {
	type InfiniteData,
	useInfiniteQuery,
	useMutation,
	useQuery,
	useQueryClient,
} from "@tanstack/react-query";
import { type ApiError, apiFetch } from "./api";
import { jsonRequest } from "./request";

export function useGuestLink(groupId: string, enabled = true) {
	return useQuery<GuestLinkDto, ApiError>({
		queryKey: ["group", groupId, "guest-link"],
		enabled,
		queryFn: async () =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/guest-link`,
					GuestLinkResponse,
				)
			).guestLink,
	});
}

export function useEnableGuestLink(groupId: string) {
	const client = useQueryClient();
	return useMutation<GuestLinkDto, ApiError, { rotate?: boolean } | undefined>({
		mutationFn: async (input) =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/guest-link`,
					GuestLinkResponse,
					jsonRequest("POST", input ?? {}),
				)
			).guestLink,
		onSuccess: async (guestLink) => {
			client.setQueryData(["group", groupId, "guest-link"], guestLink);
			await client.invalidateQueries({
				queryKey: ["group", groupId, "activity"],
			});
		},
	});
}

export function useRevokeGuestLink(groupId: string) {
	const client = useQueryClient();
	return useMutation<GuestLinkDto, ApiError, void>({
		mutationFn: async () =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/guest-link`,
					GuestLinkResponse,
					jsonRequest("DELETE"),
				)
			).guestLink,
		onSuccess: async (guestLink) => {
			client.setQueryData(["group", groupId, "guest-link"], guestLink);
			await client.invalidateQueries({
				queryKey: ["group", groupId, "activity"],
			});
		},
	});
}

export function useGuestGroupView(
	token: string,
	options: { cycleId?: "current" | string } = {},
) {
	const cycleId = options.cycleId;
	return useInfiniteQuery<
		GuestGroupViewResponse,
		ApiError,
		InfiniteData<GuestGroupViewResponse>,
		readonly ["guest-link", string, string | null],
		string | null
	>({
		queryKey: ["guest-link", token, cycleId ?? null],
		initialPageParam: null,
		queryFn: ({ pageParam }) => {
			const params = new URLSearchParams({ limit: "100" });
			if (cycleId) params.set("cycleId", cycleId);
			if (pageParam !== null) params.set("cursor", pageParam);
			return apiFetch(
				`/guest-links/${encodeURIComponent(token)}?${params.toString()}`,
				GuestGroupViewResponse,
			);
		},
		getNextPageParam: (page) => page.transactions.nextCursor,
		retry: (count, error) => error.status !== 404 && count < 1,
	});
}
