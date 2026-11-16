"use client";
import { ParseResponse } from "@songphang/contract";
import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { type ApiError, apiFetch } from "./api";
import { jsonRequest } from "./request";
export function useParseSentence(groupId: string, text: string) {
	const [debounced, setDebounced] = useState(text);
	useEffect(() => {
		const timer = setTimeout(() => setDebounced(text), 300);
		return () => clearTimeout(timer);
	}, [text]);
	const query = useQuery<ParseResponse, ApiError>({
		queryKey: ["group", groupId, "parse", debounced],
		enabled: !!debounced.trim(),
		queryFn: () =>
			apiFetch(
				`/groups/${encodeURIComponent(groupId)}/transactions/parse`,
				ParseResponse,
				jsonRequest("POST", { text: debounced }),
			),
		placeholderData: keepPreviousData,
	});
	return {
		...query,
		send: () => {
			setDebounced(text);
			if (text === debounced) void query.refetch();
		},
		current:
			query.data?.text === text &&
			!query.isFetching &&
			!query.isPlaceholderData,
	};
}
