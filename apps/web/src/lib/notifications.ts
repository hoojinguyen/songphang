"use client";
import {
	GroupMuteResponse,
	type MarkNotificationsReadRequest,
	NotificationSettingsDto,
	NotificationsListResponse,
	UnreadCountResponse,
	type UpdateNotificationSettingsRequest,
} from "@songphang/contract";
import {
	useInfiniteQuery,
	useMutation,
	useQuery,
	useQueryClient,
} from "@tanstack/react-query";
import { type ApiError, apiFetch, apiSend } from "./api";
import { jsonRequest } from "./request";

export function useNotifications() {
	return useInfiniteQuery<NotificationsListResponse, ApiError>({
		queryKey: ["notifications", "list"],
		initialPageParam: undefined as string | undefined,
		queryFn: ({ pageParam }) => {
			const params = new URLSearchParams({ limit: "30" });
			if (typeof pageParam === "string") params.set("cursor", pageParam);
			return apiFetch(
				`/me/notifications?${params.toString()}`,
				NotificationsListResponse,
			);
		},
		getNextPageParam: (lastPage) => lastPage.nextCursor ?? undefined,
		refetchOnWindowFocus: true,
	});
}

export function useUnreadNotificationCount() {
	return useQuery<UnreadCountResponse, ApiError>({
		queryKey: ["notifications", "unread-count"],
		queryFn: () =>
			apiFetch("/me/notifications/unread-count", UnreadCountResponse),
		refetchOnWindowFocus: true,
	});
}

export function useMarkNotificationsRead() {
	const client = useQueryClient();
	return useMutation<void, ApiError, MarkNotificationsReadRequest>({
		mutationFn: (request) =>
			apiSend("/me/notifications/read", jsonRequest("POST", request)),
		onSuccess: async () => {
			await client.invalidateQueries({ queryKey: ["notifications"] });
		},
	});
}

export function useSetGroupMuted(groupId: string) {
	const client = useQueryClient();
	return useMutation<GroupMuteResponse, ApiError, boolean>({
		mutationFn: (muted) =>
			apiFetch(
				`/groups/${encodeURIComponent(groupId)}/me/muted`,
				GroupMuteResponse,
				jsonRequest("PUT", { muted }),
			),
		onSuccess: async () => {
			await client.invalidateQueries({ queryKey: ["group", groupId] });
		},
	});
}

export function useNotificationSettings() {
	return useQuery<NotificationSettingsDto, ApiError>({
		queryKey: ["notifications", "settings"],
		queryFn: () =>
			apiFetch("/me/notification-settings", NotificationSettingsDto),
	});
}

export function useUpdateNotificationSettings() {
	const client = useQueryClient();
	return useMutation<
		NotificationSettingsDto,
		ApiError,
		UpdateNotificationSettingsRequest
	>({
		mutationFn: (request) =>
			apiFetch(
				"/me/notification-settings",
				NotificationSettingsDto,
				jsonRequest("PUT", request),
			),
		onSuccess: (data) => {
			client.setQueryData(["notifications", "settings"], data);
		},
	});
}

export async function postUnsubscribe(token: string): Promise<void> {
	return apiSend("/notifications/unsubscribe", jsonRequest("POST", { token }));
}
