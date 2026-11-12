"use client";
import {
	type CreateGroupRequest,
	GroupResponse,
	GroupsResponse,
	type UpdateGroupRequest,
} from "@songphang/contract";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { type ApiError, apiFetch } from "./api";
import { jsonRequest } from "./request";
export function useGroups() {
	return useQuery<Awaited<ReturnType<typeof fetchGroups>>, ApiError>({
		queryKey: ["groups"],
		queryFn: fetchGroups,
	});
}
async function fetchGroups() {
	return (await apiFetch("/groups", GroupsResponse)).groups;
}
export function useGroup(groupId: string) {
	return useQuery<Awaited<ReturnType<typeof fetchGroup>>, ApiError>({
		queryKey: ["group", groupId],
		queryFn: () => fetchGroup(groupId),
	});
}
async function fetchGroup(groupId: string) {
	return (
		await apiFetch(`/groups/${encodeURIComponent(groupId)}`, GroupResponse)
	).group;
}
export function useCreateGroup() {
	const client = useQueryClient();
	return useMutation<
		Awaited<ReturnType<typeof fetchGroup>>,
		ApiError,
		{ request: CreateGroupRequest; key: string }
	>({
		mutationFn: async ({ request, key }) =>
			(
				await apiFetch(
					"/groups",
					GroupResponse,
					jsonRequest("POST", request, key),
				)
			).group,
		onSuccess: async (group) => {
			await Promise.all([
				client.invalidateQueries({ queryKey: ["groups"] }),
				client.invalidateQueries({ queryKey: ["group", group.id] }),
			]);
		},
	});
}
export function useUpdateGroup(groupId: string) {
	const client = useQueryClient();
	return useMutation<
		Awaited<ReturnType<typeof fetchGroup>>,
		ApiError,
		UpdateGroupRequest
	>({
		mutationFn: async (request) =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}`,
					GroupResponse,
					jsonRequest("PATCH", request),
				)
			).group,
		onSuccess: async () => {
			await Promise.all([
				client.invalidateQueries({ queryKey: ["groups"] }),
				client.invalidateQueries({ queryKey: ["group", groupId] }),
			]);
		},
	});
}
