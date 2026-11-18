"use client";
import {
	ChatIdentitiesResponse,
	ChatLinksResponse,
	type ChatPlatform,
	CreateChatLinkCodeResponse,
} from "@songphang/contract";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import type { z } from "zod";
import { type ApiError, apiFetch, apiSend } from "./api";

export function useGroupChatLinks(groupId: string, enabled = true) {
	return useQuery<z.infer<typeof ChatLinksResponse>, ApiError>({
		queryKey: ["group-chat-links", groupId],
		queryFn: () => apiFetch(`/groups/${groupId}/chat-links`, ChatLinksResponse),
		enabled,
	});
}

export function useCreateGroupChatLinkCode(groupId: string) {
	return useMutation<
		z.infer<typeof CreateChatLinkCodeResponse>,
		ApiError,
		void
	>({
		mutationFn: () =>
			apiFetch(
				`/groups/${groupId}/chat-links/code`,
				CreateChatLinkCodeResponse,
				{
					method: "POST",
				},
			),
	});
}

export function useUnlinkGroupChat(groupId: string) {
	const client = useQueryClient();
	return useMutation<void, ApiError, string>({
		mutationFn: (chatLinkId) =>
			apiSend(`/groups/${groupId}/chat-links/${chatLinkId}`, {
				method: "DELETE",
			}),
		onSuccess: () => {
			void client.invalidateQueries({
				queryKey: ["group-chat-links", groupId],
			});
		},
	});
}

export function useMyChatIdentities(enabled = true) {
	return useQuery<z.infer<typeof ChatIdentitiesResponse>, ApiError>({
		queryKey: ["me", "chat-identities"],
		queryFn: () => apiFetch("/me/chat-identities", ChatIdentitiesResponse),
		enabled,
	});
}

export function useClaimChatIdentity() {
	const client = useQueryClient();
	return useMutation<void, ApiError, string>({
		mutationFn: (code) =>
			apiSend("/me/chat-identities/claim", {
				method: "POST",
				headers: { "Content-Type": "application/json" },
				body: JSON.stringify({ code }),
			}),
		onSuccess: () => {
			void client.invalidateQueries({ queryKey: ["me", "chat-identities"] });
		},
	});
}

export function useUnlinkChatIdentity() {
	const client = useQueryClient();
	return useMutation<void, ApiError, ChatPlatform>({
		mutationFn: (platform) =>
			apiSend(`/me/chat-identities/${platform}`, { method: "DELETE" }),
		onSuccess: () => {
			void client.invalidateQueries({ queryKey: ["me", "chat-identities"] });
		},
	});
}
