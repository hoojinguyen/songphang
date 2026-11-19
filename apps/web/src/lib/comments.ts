"use client";
import {
	type CommentResponse,
	CommentResponse as CommentResponseSchema,
	CommentsResponse,
	type DisputeResponse,
	DisputeResponse as DisputeResponseSchema,
} from "@songphang/contract";
import {
	type InfiniteData,
	useInfiniteQuery,
	useMutation,
	useQueryClient,
} from "@tanstack/react-query";
import type { z } from "zod";
import { type ApiError, apiFetch, apiSend } from "./api";
import { jsonRequest } from "./request";

type CommentsPage = z.infer<typeof CommentsResponse>;

export function useComments(groupId: string, transactionId: string) {
	return useInfiniteQuery<
		CommentsPage,
		ApiError,
		InfiniteData<CommentsPage>,
		readonly ["group", string, "comments", string],
		string | null
	>({
		queryKey: ["group", groupId, "comments", transactionId],
		initialPageParam: null,
		queryFn: ({ pageParam }) => {
			const params = new URLSearchParams({ limit: "50" });
			if (pageParam !== null) params.set("cursor", pageParam);
			return apiFetch(
				`/groups/${encodeURIComponent(groupId)}/transactions/${encodeURIComponent(transactionId)}/comments?${params.toString()}`,
				CommentsResponse,
			);
		},
		getNextPageParam: (page) => page.nextCursor,
	});
}

function useInvalidateCommentsAndTx(groupId: string, transactionId: string) {
	const client = useQueryClient();
	return async () => {
		await Promise.all([
			client.invalidateQueries({
				queryKey: ["group", groupId, "comments", transactionId],
			}),
			client.invalidateQueries({
				queryKey: ["group", groupId, "transactions"],
			}),
		]);
	};
}

export function useCreateComment(groupId: string, transactionId: string) {
	const invalidate = useInvalidateCommentsAndTx(groupId, transactionId);
	return useMutation<CommentResponse, ApiError, { body: string; key: string }>({
		mutationFn: ({ body, key }) =>
			apiFetch(
				`/groups/${encodeURIComponent(groupId)}/transactions/${encodeURIComponent(transactionId)}/comments`,
				CommentResponseSchema,
				jsonRequest("POST", { body }, key),
			),
		onSuccess: invalidate,
	});
}

export function useDeleteComment(groupId: string, transactionId: string) {
	const invalidate = useInvalidateCommentsAndTx(groupId, transactionId);
	return useMutation<void, ApiError, string>({
		mutationFn: (commentId) =>
			apiSend(
				`/groups/${encodeURIComponent(groupId)}/transactions/${encodeURIComponent(transactionId)}/comments/${encodeURIComponent(commentId)}`,
				jsonRequest("DELETE"),
			),
		onSuccess: invalidate,
	});
}

export function useOpenDispute(groupId: string, transactionId: string) {
	const client = useQueryClient();
	return useMutation<DisputeResponse, ApiError, string>({
		mutationFn: (reason) =>
			apiFetch(
				`/groups/${encodeURIComponent(groupId)}/transactions/${encodeURIComponent(transactionId)}/dispute`,
				DisputeResponseSchema,
				jsonRequest("POST", { reason }),
			),
		onSuccess: async () => {
			await Promise.all([
				client.invalidateQueries({
					queryKey: ["group", groupId, "transactions"],
				}),
				client.invalidateQueries({ queryKey: ["group", groupId, "activity"] }),
			]);
		},
	});
}

export function useResolveDispute(groupId: string, transactionId: string) {
	const client = useQueryClient();
	return useMutation<DisputeResponse, ApiError, void>({
		mutationFn: () =>
			apiFetch(
				`/groups/${encodeURIComponent(groupId)}/transactions/${encodeURIComponent(transactionId)}/dispute/resolve`,
				DisputeResponseSchema,
				jsonRequest("POST"),
			),
		onSuccess: async () => {
			await Promise.all([
				client.invalidateQueries({
					queryKey: ["group", groupId, "transactions"],
				}),
				client.invalidateQueries({ queryKey: ["group", groupId, "activity"] }),
			]);
		},
	});
}
