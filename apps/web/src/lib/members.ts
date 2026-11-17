"use client";
import {
	type CreateMemberRequest,
	type MemberDto,
	MemberResponse,
	MembersResponse,
	type PaymentMethodInput,
	type UpdateMemberRequest,
} from "@songphang/contract";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { type ApiError, apiFetch, apiSend } from "./api";
import { jsonRequest } from "./request";
export function useMembers(groupId: string) {
	return useQuery<MemberDto[], ApiError>({
		queryKey: ["group", groupId, "members"],
		queryFn: async () =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/members`,
					MembersResponse,
				)
			).members,
	});
}

async function invalidateMembers(
	client: ReturnType<typeof useQueryClient>,
	groupId: string,
) {
	await Promise.all([
		client.invalidateQueries({ queryKey: ["group", groupId], exact: true }),
		client.invalidateQueries({ queryKey: ["group", groupId, "users"] }),
		client.invalidateQueries({ queryKey: ["group", groupId, "members"] }),
		client.invalidateQueries({ queryKey: ["group", groupId, "balances"] }),
		client.invalidateQueries({ queryKey: ["groups"] }),
	]);
}
export function useCreateMember(groupId: string) {
	const client = useQueryClient();
	return useMutation<
		MemberDto,
		ApiError,
		{ request: CreateMemberRequest; key: string }
	>({
		mutationFn: async ({ request, key }) =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/members`,
					MemberResponse,
					jsonRequest("POST", request, key),
				)
			).member,
		onSuccess: () => invalidateMembers(client, groupId),
	});
}
export function useUpdateMember(groupId: string) {
	const client = useQueryClient();
	return useMutation<
		MemberDto,
		ApiError,
		{ memberId: string; request: UpdateMemberRequest }
	>({
		mutationFn: async ({ memberId, request }) =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/members/${encodeURIComponent(memberId)}`,
					MemberResponse,
					jsonRequest("PATCH", request),
				)
			).member,
		onSuccess: () => invalidateMembers(client, groupId),
	});
}
export function useDeleteMember(groupId: string) {
	const client = useQueryClient();
	return useMutation<void, ApiError, string>({
		mutationFn: (memberId) =>
			apiSend(
				`/groups/${encodeURIComponent(groupId)}/members/${encodeURIComponent(memberId)}`,
				jsonRequest("DELETE"),
			),
		onSuccess: () => invalidateMembers(client, groupId),
	});
}

export function usePaymentMethods(groupId: string) {
	const client = useQueryClient();
	return useMutation<
		MemberDto,
		ApiError,
		{ memberId: string; methods: PaymentMethodInput[] }
	>({
		mutationFn: async ({ memberId, methods }) =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/members/${encodeURIComponent(memberId)}/payment-methods`,
					MemberResponse,
					jsonRequest("PUT", { methods }),
				)
			).member,
		onSuccess: () => invalidateMembers(client, groupId),
	});
}
