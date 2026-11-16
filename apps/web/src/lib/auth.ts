"use client";
import {
	type ChangePasswordRequest,
	type DeleteAccountRequest,
	type ForgotPasswordRequest,
	type LoginRequest,
	ProvidersResponse,
	type RegisterRequest,
	type ResetPasswordRequest,
} from "@songphang/contract";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { z } from "zod";
import { vi } from "../messages/vi";
import { type ApiError, apiFetch, apiSend } from "./api";
import { jsonRequest } from "./request";
export function useProviders() {
	return useQuery<z.infer<typeof ProvidersResponse>, ApiError>({
		queryKey: ["auth", "providers"],
		queryFn: () => apiFetch("/auth/providers", ProvidersResponse),
	});
}
export function useLogin() {
	const client = useQueryClient();
	return useMutation<void, ApiError, LoginRequest>({
		mutationFn: (request) =>
			apiSend("/auth/login", jsonRequest("POST", request)),
		onSuccess: async () => {
			await client.cancelQueries();
			client.clear();
		},
	});
}
export function useRegister() {
	return useMutation<void, ApiError, RegisterRequest>({
		mutationFn: (request) =>
			apiSend("/auth/register", jsonRequest("POST", request)),
	});
}
export function useVerifyEmail() {
	const client = useQueryClient();
	return useMutation<void, ApiError, string>({
		mutationFn: (token) =>
			apiSend("/auth/verify-email", jsonRequest("POST", { token })),
		onSuccess: () => client.invalidateQueries({ queryKey: ["me"] }),
	});
}
export function useResendVerification() {
	return useMutation<void, ApiError, void>({
		mutationFn: () => apiSend("/auth/resend-verification", jsonRequest("POST")),
	});
}
export function useForgotPassword() {
	return useMutation<void, ApiError, ForgotPasswordRequest>({
		mutationFn: (request) =>
			apiSend("/auth/forgot-password", jsonRequest("POST", request)),
	});
}
export function useResetPassword() {
	return useMutation<void, ApiError, ResetPasswordRequest>({
		mutationFn: (request) =>
			apiSend("/auth/reset-password", jsonRequest("POST", request)),
	});
}
export function passwordValidation(password: string): string | null {
	if (password.length < 10) return vi.auth.tooShort;
	if (password.length > 128) return vi.auth.passwordTooLong;
	return null;
}
export function authErrorMessage(error: ApiError | null): string | null {
	if (!error) return null;
	if (error.code === "RATE_LIMITED") return vi.login.tooMany;
	if (error.code === "INVALID_CREDENTIALS") return vi.login.invalidCredentials;
	if (error.code === "WEAK_PASSWORD") {
		const parsed = z
			.object({ reason: z.enum(["too_short", "too_long", "too_common"]) })
			.safeParse(error.details);
		if (parsed.success)
			return parsed.data.reason === "too_short"
				? vi.auth.tooShort
				: parsed.data.reason === "too_long"
					? vi.auth.passwordTooLong
					: vi.auth.tooCommon;
	}
	return vi.common.saveError;
}

export function useChangePassword() {
	return useMutation<void, ApiError, ChangePasswordRequest>({
		mutationFn: (request) =>
			apiSend("/auth/change-password", jsonRequest("POST", request)),
	});
}
export function useDeleteAccount() {
	const router = useRouter();
	const client = useQueryClient();
	return useMutation<void, ApiError, DeleteAccountRequest>({
		mutationFn: (request) => apiSend("/me", jsonRequest("DELETE", request)),
		onSuccess: async () => {
			await client.cancelQueries();
			client.clear();
			router.replace("/login");
		},
	});
}
