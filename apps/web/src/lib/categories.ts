"use client";
import { CategoriesResponse, type CategoryDto } from "@songphang/contract";
import { useQuery } from "@tanstack/react-query";
import { type ApiError, apiFetch } from "./api";

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
