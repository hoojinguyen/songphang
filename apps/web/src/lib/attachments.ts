"use client";
import {
	type AttachmentDto,
	AttachmentResponse,
	ErrorResponse,
} from "@songphang/contract";
import { ApiError } from "./api";
import {
	connectionSnapshot,
	requestFailed,
	requestSucceeded,
} from "./network-state";

export function attachmentContentUrl(
	groupId: string,
	attachmentId: string,
): string {
	return `/api/v1/groups/${encodeURIComponent(groupId)}/attachments/${encodeURIComponent(attachmentId)}/content`;
}

export async function uploadAttachment(
	groupId: string,
	blob: Blob,
	filename = "hoa-don.jpg",
): Promise<AttachmentDto> {
	if (!connectionSnapshot().online) {
		requestFailed();
		throw new ApiError("Offline", {
			status: 0,
			code: "NETWORK",
			requestId: null,
		});
	}
	const formData = new FormData();
	formData.append("file", blob, filename);
	let response: Response;
	try {
		response = await fetch(
			`/api/v1/groups/${encodeURIComponent(groupId)}/attachments`,
			{
				method: "POST",
				body: formData,
				cache: "no-store",
				credentials: "include",
			},
		);
	} catch {
		requestFailed();
		throw new ApiError("Upload failed", {
			status: 0,
			code: "NETWORK",
			requestId: null,
		});
	}
	let body: unknown;
	try {
		body = await response.json();
	} catch {
		requestFailed();
		throw new ApiError("Invalid response", {
			status: response.status,
			code: "NETWORK",
			requestId: null,
		});
	}
	if (!response.ok) {
		const errParsed = ErrorResponse.safeParse(body);
		if (!errParsed.success) {
			requestFailed();
			throw new ApiError("Upload failed", {
				status: response.status,
				code: "NETWORK",
				requestId: null,
			});
		}
		requestSucceeded();
		const error = errParsed.data.error;
		throw new ApiError(error.message, {
			status: response.status,
			code: error.code,
			requestId: error.requestId,
			...(error.details === undefined ? {} : { details: error.details }),
		});
	}
	const parsed = AttachmentResponse.safeParse(body);
	if (!parsed.success) {
		requestFailed();
		throw new ApiError("Invalid attachment response", {
			status: 0,
			code: "NETWORK",
			requestId: null,
		});
	}
	requestSucceeded();
	return parsed.data.attachment;
}
