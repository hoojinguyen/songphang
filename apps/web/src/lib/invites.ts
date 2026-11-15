"use client";
import {
	InvitePreviewResponse,
	InviteResponse,
	type JoinRequest,
	JoinResponse,
} from "@songphang/contract";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { type ApiError, apiFetch } from "./api";
import { jsonRequest } from "./request";
export function useInvitePreview(token: string) {
	return useQuery<Awaited<ReturnType<typeof fetchPreview>>, ApiError>({
		queryKey: ["invite", token],
		queryFn: () => fetchPreview(token),
		retry: (count, error) =>
			error.status !== 404 && error.status !== 401 && count < 1,
	});
}
function fetchPreview(token: string) {
	return apiFetch(
		`/invites/${encodeURIComponent(token)}`,
		InvitePreviewResponse,
	);
}
export function useJoin(token: string) {
	const client = useQueryClient();
	return useMutation<
		{ groupId: string },
		ApiError,
		{ request: JoinRequest; key: string }
	>({
		mutationFn: ({ request, key }) =>
			apiFetch(
				`/invites/${encodeURIComponent(token)}/join`,
				JoinResponse,
				jsonRequest("POST", request, key),
			),
		onSuccess: () => client.invalidateQueries({ queryKey: ["groups"] }),
	});
}
export function useInvite(groupId: string) {
	return useQuery<Awaited<ReturnType<typeof fetchInvite>>, ApiError>({
		queryKey: ["group", groupId, "invite"],
		queryFn: () => fetchInvite(groupId),
	});
}
async function fetchInvite(groupId: string) {
	return (
		await apiFetch(
			`/groups/${encodeURIComponent(groupId)}/invite`,
			InviteResponse,
		)
	).invite;
}
export function useChangeInvite(groupId: string) {
	const client = useQueryClient();
	return useMutation<void, ApiError, { active: boolean } | { rotate: true }>({
		mutationFn: async (request) => {
			await apiFetch(
				`/groups/${encodeURIComponent(groupId)}/invite${"rotate" in request ? "/rotate" : ""}`,
				InviteResponse,
				jsonRequest(
					"rotate" in request ? "POST" : "PATCH",
					"rotate" in request ? undefined : request,
				),
			);
		},
		onSuccess: () =>
			client.invalidateQueries({ queryKey: ["group", groupId, "invite"] }),
	});
}
