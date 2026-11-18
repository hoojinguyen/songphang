import { createMiddleware } from "hono/factory";
import type { AppEnv } from "../app.js";
import { AppError } from "../errors.js";

const MAX_UPLOAD_BODY_BYTES = 6 * 1024 * 1024;
const MAX_FILE_BYTES = 5_242_880;

export function streamingUploadLimit() {
	return createMiddleware<AppEnv>(async (context, next) => {
		const rawLength = context.req.header("Content-Length");
		if (rawLength !== undefined) {
			const trimmed = rawLength.trim();
			if (!/^\d+$/.test(trimmed)) {
				throw new AppError(
					400,
					"VALIDATION_FAILED",
					"Invalid Content-Length header",
				);
			}
			if (Number(trimmed) > MAX_UPLOAD_BODY_BYTES) {
				throw new AppError(
					413,
					"VALIDATION_FAILED",
					"Request body is too large",
				);
			}
		}
		const body = context.req.raw.body;
		if (body) {
			const reader = body.getReader();
			const chunks: Uint8Array[] = [];
			let totalBytes = 0;
			for (;;) {
				const { done, value } = await reader.read();
				if (done) break;
				totalBytes += value.byteLength;
				if (totalBytes > MAX_UPLOAD_BODY_BYTES) {
					await reader.cancel().catch(() => {});
					throw new AppError(
						413,
						"VALIDATION_FAILED",
						"Request body is too large",
					);
				}
				chunks.push(value);
			}
			const combined = new Uint8Array(totalBytes);
			let offset = 0;
			for (const chunk of chunks) {
				combined.set(chunk, offset);
				offset += chunk.byteLength;
			}
			const headers = new Headers(context.req.raw.headers);
			headers.delete("transfer-encoding");
			headers.set("content-length", String(totalBytes));
			context.req.raw = new Request(context.req.raw.url, {
				method: context.req.raw.method,
				headers,
				body: combined,
			});
		}
		await next();
	});
}

export async function readSingleUploadedFile(
	request: Request,
): Promise<Uint8Array> {
	let formData: FormData;
	try {
		formData = await request.formData();
	} catch {
		throw new AppError(
			400,
			"VALIDATION_FAILED",
			"Expected multipart/form-data",
		);
	}
	const keys = [...formData.keys()];
	const files = formData.getAll("file");
	if (keys.length !== 1 || keys[0] !== "file" || files.length !== 1) {
		throw new AppError(
			400,
			"VALIDATION_FAILED",
			"Exactly one 'file' part is required",
		);
	}
	const entry = files[0];
	if (!(entry instanceof File)) {
		throw new AppError(400, "VALIDATION_FAILED", "Part 'file' must be a file");
	}
	if (entry.size === 0 || entry.size > MAX_FILE_BYTES) {
		throw new AppError(400, "VALIDATION_FAILED", "Invalid file size", {
			reason: "too_large",
		});
	}
	const bytes = new Uint8Array(await entry.arrayBuffer());
	if (bytes.byteLength === 0 || bytes.byteLength > MAX_FILE_BYTES) {
		throw new AppError(400, "VALIDATION_FAILED", "Invalid file size", {
			reason: "too_large",
		});
	}
	return bytes;
}
