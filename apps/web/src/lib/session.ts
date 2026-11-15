"use client";
import { MeResponse, type UserDto } from "@songphang/contract";
import {
	type UseMutationResult,
	type UseQueryResult,
	useMutation,
	useQuery,
	useQueryClient,
} from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { type ApiError, apiFetch, apiSend } from "./api";

export function loginPath(returnTo: string): string {
	return `/login?next=${encodeURIComponent(returnTo)}`;
}
export function safeNext(raw: string | null): string {
	if (
		raw === null ||
		!raw.startsWith("/") ||
		raw.startsWith("//") ||
		raw.includes("\\") ||
		Array.from(raw).some(
			(character) =>
				character.charCodeAt(0) < 32 || character.charCodeAt(0) === 127,
		)
	)
		return "/";
	return raw;
}
export function useMe(): UseQueryResult<UserDto, ApiError> {
	return useQuery<UserDto, ApiError>({
		queryKey: ["me"],
		queryFn: async () => (await apiFetch("/me", MeResponse)).user,
		retry: (count, error) => error.status !== 401 && count < 1,
	});
}
export function useLogout(): UseMutationResult<void, ApiError, void> {
	const router = useRouter();
	const queryClient = useQueryClient();
	return useMutation<void, ApiError, void>({
		mutationFn: () => apiSend("/auth/logout", { method: "POST" }),
		onSettled: async (_, error) => {
			if (error !== null && error.status !== 401) return;
			await queryClient.cancelQueries();
			queryClient.clear();
			router.replace("/login");
		},
	});
}
