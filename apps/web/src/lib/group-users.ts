"use client";
import {
	GroupResponse,
	type GroupUserDto,
	GroupUsersResponse,
} from "@songphang/contract";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { type ApiError, apiFetch, apiSend } from "./api";
import { jsonRequest } from "./request";
export function useGroupUsers(groupId: string) {
	return useQuery<GroupUserDto[], ApiError>({
		queryKey: ["group", groupId, "users"],
		queryFn: async () =>
			(
				await apiFetch(
					`/groups/${encodeURIComponent(groupId)}/users`,
					GroupUsersResponse,
				)
			).users,
	});
}
type UserAction =
	| { action: "role"; userId: string; role: "editor" | "viewer" }
	| { action: "remove"; userId: string }
	| { action: "transfer"; userId: string }
	| { action: "choose"; memberId: string }
	| { action: "leave" };
export function useGroupUserAction(groupId: string) {
	const client = useQueryClient();
	const router = useRouter();
	const path = `/groups/${encodeURIComponent(groupId)}`;
	return useMutation<void, ApiError, UserAction>({
		mutationFn: async (request) => {
			switch (request.action) {
				case "role":
					await apiFetch(
						`${path}/users/${encodeURIComponent(request.userId)}`,
						GroupUsersResponse,
						jsonRequest("PATCH", { role: request.role }),
					);
					break;
				case "remove":
					await apiSend(
						`${path}/users/${encodeURIComponent(request.userId)}`,
						jsonRequest("DELETE"),
					);
					break;
				case "leave":
					await apiSend(`${path}/leave`, jsonRequest("POST"));
					break;
				case "transfer":
					await apiFetch(
						`${path}/transfer-ownership`,
						GroupResponse,
						jsonRequest("POST", { userId: request.userId }),
					);
					break;
				case "choose":
					await apiFetch(`${path}/me/member`, GroupResponse, {
						...jsonRequest("POST", { memberId: request.memberId }),
						method: "PUT",
					});
					break;
			}
		},
		onSuccess: async (_, request) => {
			if (request.action === "transfer")
				router.replace(`/g/${groupId}/members`);
			if (request.action === "leave") router.replace("/");
			await Promise.all([
				client.invalidateQueries({ queryKey: ["group", groupId] }),
				client.invalidateQueries({ queryKey: ["groups"] }),
			]);
		},
	});
}
