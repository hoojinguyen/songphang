import { ErrorResponse } from "@songphang/contract";
import type { ZodType } from "zod";
import {
	connectionSnapshot,
	requestFailed,
	requestSucceeded,
} from "./network-state";

export class ApiError extends Error {
	readonly status: number;
	readonly code: string;
	readonly requestId: string | null;
	readonly details: Record<string, unknown> | undefined;
	constructor(
		message: string,
		details: {
			status: number;
			code: string;
			requestId: string | null;
			details?: Record<string, unknown>;
		},
	) {
		super(message);
		this.name = "ApiError";
		this.status = details.status;
		this.code = details.code;
		this.requestId = details.requestId;
		this.details = details.details;
	}
}
function networkError(): ApiError {
	requestFailed();
	return new ApiError("The API response could not be read", {
		status: 0,
		code: "NETWORK",
		requestId: null,
	});
}
async function sendRequest(
	path: string,
	init?: RequestInit,
): Promise<Response> {
	if (init?.method && init.method !== "GET" && !connectionSnapshot().online)
		throw networkError();
	try {
		return await fetch(`/api/v1${path}`, {
			...init,
			cache: "no-store",
			credentials: "include",
		});
	} catch {
		throw networkError();
	}
}
async function readResponse(response: Response): Promise<unknown> {
	let body: unknown;
	try {
		body = await response.json();
	} catch {
		throw networkError();
	}
	if (!response.ok) {
		const parsed = ErrorResponse.safeParse(body);
		if (!parsed.success) throw networkError();
		requestSucceeded();
		const error = parsed.data.error;
		throw new ApiError(error.message, {
			status: response.status,
			code: error.code,
			requestId: error.requestId,
			...(error.details === undefined ? {} : { details: error.details }),
		});
	}
	return body;
}
export async function apiFetch<T>(
	path: string,
	schema: ZodType<T>,
	init?: RequestInit,
): Promise<T> {
	const response = await sendRequest(path, init);
	const parsed = schema.safeParse(await readResponse(response));
	if (!parsed.success) throw networkError();
	requestSucceeded();
	return parsed.data;
}
export async function apiSend(path: string, init: RequestInit): Promise<void> {
	const response = await sendRequest(path, init);
	if (response.status === 204) {
		requestSucceeded();
		return;
	}
	await readResponse(response);
	throw networkError();
}
