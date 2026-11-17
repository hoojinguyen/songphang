"use client";
import {
	type CreateFundRequest,
	type MemberDto,
	MemberResponse,
	type UpdateFundRequest,
} from "@songphang/contract";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { type ApiError, apiFetch, apiSend } from "./api";
import { jsonRequest } from "./request";

async function invalidateFund(
	client: ReturnType<typeof useQueryClient>,
	groupId: string,
) {
	await Promise.all([
		client.invalidateQueries({ queryKey: ["group", groupId], exact: true }),
		client.invalidateQueries({ queryKey: ["group", groupId, "members"] }),
		client.invalidateQueries({ queryKey: ["group", groupId, "balances"] }),
		client.invalidateQueries({ queryKey: ["group", groupId, "activity"] }),
		client.invalidateQueries({ queryKey: ["groups"] }),
	]);
}

export function useCreateFund(groupId: string) {
	const client = useQueryClient();
	return useMutation<
		MemberDto,
		ApiError,
		{ request: CreateFundRequest; key: string }
	>({
		mutationFn: async ({ request, key }) =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/fund`,
					MemberResponse,
					jsonRequest("POST", request, key),
				)
			).member,
		onSuccess: () => invalidateFund(client, groupId),
	});
}

export function useUpdateFund(groupId: string) {
	const client = useQueryClient();
	return useMutation<MemberDto, ApiError, UpdateFundRequest>({
		mutationFn: async (request) =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/fund`,
					MemberResponse,
					jsonRequest("PATCH", request),
				)
			).member,
		onSuccess: () => invalidateFund(client, groupId),
	});
}

export function useDeleteFund(groupId: string) {
	const client = useQueryClient();
	return useMutation<void, ApiError, void>({
		mutationFn: () =>
			apiSend(
				`/groups/${encodeURIComponent(groupId)}/fund`,
				jsonRequest("DELETE"),
			),
		onSuccess: () => invalidateFund(client, groupId),
	});
}
