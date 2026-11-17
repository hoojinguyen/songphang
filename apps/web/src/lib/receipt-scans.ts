"use client";
import {
	PreviewItemsRequest,
	PreviewItemsResponse,
	ReceiptScanResponse,
} from "@songphang/contract";
import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { type ApiError, apiFetch } from "./api";
import { jsonRequest } from "./request";

const PENDING_TIMEOUT_MS = 60_000;
const FALLBACK_POLL_MS = 3_000;
const PREVIEW_DEBOUNCE_MS = 300;

export function createReceiptScan(
	groupId: string,
	attachmentId: string,
	key: string,
): Promise<ReceiptScanResponse> {
	return apiFetch(
		`/groups/${encodeURIComponent(groupId)}/receipt-scans`,
		ReceiptScanResponse,
		jsonRequest("POST", { attachmentId }, key),
	);
}

export function useReceiptScan(groupId: string, scanId: string | null) {
	const [timedOutScanId, setTimedOutScanId] = useState<string | null>(null);
	const timedOut = Boolean(scanId && timedOutScanId === scanId);

	const query = useQuery<ReceiptScanResponse, ApiError>({
		queryKey: ["group", groupId, "receiptScans", scanId],
		enabled: Boolean(scanId),
		queryFn: () =>
			apiFetch(
				`/groups/${encodeURIComponent(groupId)}/receipt-scans/${encodeURIComponent(scanId ?? "")}`,
				ReceiptScanResponse,
			),
		refetchInterval: (currentQuery) => {
			const status = currentQuery.state.data?.scan.status;
			if (timedOut) return false;
			return status === "queued" || status === "processing"
				? FALLBACK_POLL_MS
				: false;
		},
	});

	const status = query.data?.scan.status;
	const pending = status === "queued" || status === "processing";

	useEffect(() => {
		if (!pending || timedOut || !scanId) return;
		const timer = setTimeout(
			() => setTimedOutScanId(scanId),
			PENDING_TIMEOUT_MS,
		);
		return () => clearTimeout(timer);
	}, [pending, timedOut, scanId]);

	return {
		...query,
		timedOut,
	};
}

export function usePreviewItems(
	groupId: string,
	request: PreviewItemsRequest | null,
) {
	const serialized = request === null ? null : JSON.stringify(request);
	const [debounced, setDebounced] = useState<PreviewItemsRequest | null>(null);

	useEffect(() => {
		const timer = setTimeout(() => {
			setDebounced(
				serialized === null
					? null
					: PreviewItemsRequest.parse(JSON.parse(serialized)),
			);
		}, PREVIEW_DEBOUNCE_MS);
		return () => clearTimeout(timer);
	}, [serialized]);

	const query = useQuery<PreviewItemsResponse, ApiError>({
		queryKey: ["group", groupId, "itemsPreview", debounced],
		enabled: request !== null && debounced !== null,
		queryFn: () =>
			apiFetch(
				`/groups/${encodeURIComponent(groupId)}/transactions/items/preview`,
				PreviewItemsResponse,
				jsonRequest("POST", debounced),
			),
		placeholderData: keepPreviousData,
	});

	return {
		...query,
		current:
			serialized === JSON.stringify(debounced) &&
			!query.isFetching &&
			!query.isPlaceholderData,
	};
}
