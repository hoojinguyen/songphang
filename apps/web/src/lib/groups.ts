"use client";
import {
	type CloneGroupRequest,
	type CreateGroupRequest,
	GroupResponse,
	type GroupStatusFilter,
	GroupsResponse,
	type UpdateGroupRequest,
} from "@songphang/contract";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { type ApiError, apiFetch, apiSend } from "./api";
import { jsonRequest } from "./request";
export function useGroups(status?: GroupStatusFilter) {
	return useQuery<Awaited<ReturnType<typeof fetchGroups>>, ApiError>({
		queryKey: ["groups", status ?? "all"],
		queryFn: () => fetchGroups(status),
	});
}
async function fetchGroups(status?: GroupStatusFilter) {
	const params = new URLSearchParams();
	if (status) params.set("status", status);
	const qs = params.toString();
	return (await apiFetch(`/groups${qs ? `?${qs}` : ""}`, GroupsResponse))
		.groups;
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
export function useArchiveGroup(groupId: string) {
	const client = useQueryClient();
	return useMutation<void, ApiError, void>({
		mutationFn: () =>
			apiSend(
				`/groups/${encodeURIComponent(groupId)}/archive`,
				jsonRequest("POST", {}),
			),
		onSuccess: async () => {
			await Promise.all([
				client.invalidateQueries({ queryKey: ["groups"] }),
				client.invalidateQueries({ queryKey: ["group", groupId] }),
				client.invalidateQueries({ queryKey: ["me", "overview"] }),
			]);
		},
	});
}
export function useUnarchiveGroup(groupId: string) {
	const client = useQueryClient();
	return useMutation<void, ApiError, void>({
		mutationFn: () =>
			apiSend(
				`/groups/${encodeURIComponent(groupId)}/unarchive`,
				jsonRequest("POST", {}),
			),
		onSuccess: async () => {
			await Promise.all([
				client.invalidateQueries({ queryKey: ["groups"] }),
				client.invalidateQueries({ queryKey: ["group", groupId] }),
				client.invalidateQueries({ queryKey: ["me", "overview"] }),
			]);
		},
	});
}
export function useCloneGroup(groupId: string) {
	const client = useQueryClient();
	return useMutation<
		Awaited<ReturnType<typeof fetchGroup>>,
		ApiError,
		{ request: CloneGroupRequest; key: string }
	>({
		mutationFn: async ({ request, key }) =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/clone`,
					GroupResponse,
					jsonRequest("POST", request, key),
				)
			).group,
		onSuccess: async () => {
			await client.invalidateQueries({ queryKey: ["groups"] });
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
