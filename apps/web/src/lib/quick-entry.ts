"use client";
import { ParseResponse } from "@songphang/contract";
import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { type ApiError, apiFetch } from "./api";
import { jsonRequest } from "./request";
export function useParseSentence(groupId: string, text: string) {
	const [debounced, setDebounced] = useState(text);
	const [sentText, setSentText] = useState<string | null>(null);
	useEffect(() => {
		const timer = setTimeout(() => setDebounced(text), 300);
		return () => clearTimeout(timer);
	}, [text]);
	useEffect(() => {
		if (text !== sentText) setSentText(null);
	}, [text, sentText]);
	const ai = sentText === debounced;
	const query = useQuery<ParseResponse, ApiError>({
		queryKey: ["group", groupId, "parse", debounced, ai],
		enabled: !!debounced.trim(),
		queryFn: () =>
			apiFetch(
				`/groups/${encodeURIComponent(groupId)}/transactions/parse`,
				ParseResponse,
				jsonRequest("POST", { text: debounced, ai }),
			),
		placeholderData: keepPreviousData,
		refetchOnWindowFocus: false,
		refetchOnReconnect: false,
	});
	return {
		...query,
		send: () => {
			if (sentText === text && debounced === text) {
				void query.refetch();
				return;
			}
			setSentText(text);
			setDebounced(text);
		},
		current:
			query.data?.text === text &&
			!query.isFetching &&
			!query.isPlaceholderData,
		sent: ai && !query.isPlaceholderData && query.data?.text === sentText,
	};
}
