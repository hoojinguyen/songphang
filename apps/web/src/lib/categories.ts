"use client";
import {
	CategoriesResponse,
	type CategoryDto,
	CategoryResponse,
	type CreateCategoryRequest,
	type UpdateCategoryRequest,
} from "@songphang/contract";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { type ApiError, apiFetch, apiSend } from "./api";
import { jsonRequest } from "./request";

export function useCategories(groupId: string) {
	return useQuery<CategoryDto[], ApiError>({
		queryKey: ["group", groupId, "categories"],
		queryFn: async () =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/categories`,
					CategoriesResponse,
				)
			).categories,
	});
}

async function invalidateCategories(
	client: ReturnType<typeof useQueryClient>,
	groupId: string,
) {
	await Promise.all([
		client.invalidateQueries({ queryKey: ["group", groupId, "categories"] }),
		client.invalidateQueries({ queryKey: ["group", groupId, "transactions"] }),
		client.invalidateQueries({ queryKey: ["group", groupId, "stats"] }),
	]);
}

export function useCreateCategory(groupId: string) {
	const client = useQueryClient();
	return useMutation<
		CategoryDto,
		ApiError,
		{ request: CreateCategoryRequest; key: string }
	>({
		mutationFn: async ({ request, key }) =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/categories`,
					CategoryResponse,
					jsonRequest("POST", request, key),
				)
			).category,
		onSuccess: () => invalidateCategories(client, groupId),
	});
}

export function useUpdateCategory(groupId: string) {
	const client = useQueryClient();
	return useMutation<
		CategoryDto,
		ApiError,
		{ id: string; request: UpdateCategoryRequest }
	>({
		mutationFn: async ({ id, request }) =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/categories/${encodeURIComponent(id)}`,
					CategoryResponse,
					jsonRequest("PATCH", request),
				)
			).category,
		onSuccess: () => invalidateCategories(client, groupId),
	});
}

export function useArchiveCategory(groupId: string) {
	const client = useQueryClient();
	return useMutation<void, ApiError, string>({
		mutationFn: (id) =>
			apiSend(
				`/groups/${encodeURIComponent(groupId)}/categories/${encodeURIComponent(id)}`,
				jsonRequest("DELETE"),
			),
		onSuccess: () => invalidateCategories(client, groupId),
	});
}
