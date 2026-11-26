"use client";
import {
	type CreateHouseholdRequest,
	type HouseholdDto,
	HouseholdResponse,
	HouseholdsResponse,
	type UpdateHouseholdRequest,
} from "@songphang/contract";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { type ApiError, apiFetch, apiSend } from "./api";
import { jsonRequest } from "./request";

export function useHouseholds(groupId: string, enabled = true) {
	return useQuery<HouseholdDto[], ApiError>({
		queryKey: ["group", groupId, "households"],
		enabled,
		queryFn: async () =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/households`,
					HouseholdsResponse,
				)
			).households,
	});
}

function useInvalidateHouseholds(groupId: string) {
	const client = useQueryClient();
	return async () => {
		await Promise.all([
			client.invalidateQueries({ queryKey: ["group", groupId, "households"] }),
			client.invalidateQueries({ queryKey: ["group", groupId, "members"] }),
			client.invalidateQueries({ queryKey: ["group", groupId, "balances"] }),
			client.invalidateQueries({ queryKey: ["group", groupId, "breakdowns"] }),
			client.invalidateQueries({ queryKey: ["group", groupId, "activity"] }),
			client.invalidateQueries({ queryKey: ["groups"] }),
			client.invalidateQueries({ queryKey: ["me", "overview"] }),
		]);
	};
}

export function useCreateHousehold(groupId: string) {
	const invalidate = useInvalidateHouseholds(groupId);
	return useMutation<
		HouseholdDto,
		ApiError,
		{ request: CreateHouseholdRequest; key: string }
	>({
		mutationFn: async ({ request, key }) =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/households`,
					HouseholdResponse,
					jsonRequest("POST", request, key),
				)
			).household,
		onSuccess: invalidate,
	});
}

export function useUpdateHousehold(groupId: string) {
	const invalidate = useInvalidateHouseholds(groupId);
	return useMutation<
		HouseholdDto,
		ApiError,
		{ householdId: string; request: UpdateHouseholdRequest }
	>({
		mutationFn: async ({ householdId, request }) =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/households/${encodeURIComponent(householdId)}`,
					HouseholdResponse,
					jsonRequest("PATCH", request),
				)
			).household,
		onSuccess: invalidate,
	});
}

export function useDeleteHousehold(groupId: string) {
	const invalidate = useInvalidateHouseholds(groupId);
	return useMutation<void, ApiError, string>({
		mutationFn: (householdId) =>
			apiSend(
				`/groups/${encodeURIComponent(groupId)}/households/${encodeURIComponent(householdId)}`,
				jsonRequest("DELETE"),
			),
		onSuccess: invalidate,
	});
}
