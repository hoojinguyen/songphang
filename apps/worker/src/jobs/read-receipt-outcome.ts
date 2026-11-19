import { AnthropicTransportError } from "@songphang/ai";
import { checkReceipt } from "@songphang/core";
import {
	finishReceiptScanDone,
	finishReceiptScanFailed,
	recordAiCall,
} from "@songphang/db";
import { z } from "zod";
import type { ReceiptReaderOutput } from "../ai/receipt-reader.js";
import { notifyGroup } from "../notify.js";
import type { WorkerDeps } from "../queue.js";

export async function finishFailedAttempt(
	deps: WorkerDeps,
	reservationId: string,
	cause: { error?: unknown; model?: string } = {},
): Promise<void> {
	const usage =
		cause.error instanceof AnthropicTransportError ? cause.error.usage : null;
	await recordAiCall(deps.db, {
		id: reservationId,
		model: usage?.model ?? cause.model ?? deps.config.aiModel ?? "",
		inputTokens: usage?.inputTokens ?? 0,
		outputTokens: usage?.outputTokens ?? 0,
		ok: false,
		finishedAt: deps.now(),
	});
}

export async function failAndNotify(
	deps: WorkerDeps,
	groupId: string,
	scanId: string,
	errorCode:
		| "NOT_A_RECEIPT"
		| "READER_UNAVAILABLE"
		| "READER_INVALID"
		| "READ_FAILED",
): Promise<void> {
	await finishReceiptScanFailed(deps.db, {
		scanId,
		errorCode,
		finishedAt: deps.now(),
	});
	await notifyGroup(deps.db, groupId, ["receiptScans"]);
}

export async function applyReadingOutcome(
	deps: WorkerDeps,
	input: {
		scanId: string;
		groupId: string;
		reservationId: string;
		output: ReceiptReaderOutput;
	},
): Promise<void> {
	const finishedAt = deps.now();
	await recordAiCall(deps.db, {
		id: input.reservationId,
		model: input.output.model,
		inputTokens: input.output.inputTokens,
		outputTokens: input.output.outputTokens,
		ok: true,
		finishedAt,
	});
	const checked = checkReceipt(input.output.reading);
	if (checked.status === "failed") {
		await failAndNotify(deps, input.groupId, input.scanId, checked.errorCode);
		return;
	}
	await finishReceiptScanDone(deps.db, {
		scanId: input.scanId,
		result: {
			reading: input.output.reading,
			computed: checked.computed,
			flags: checked.flags,
		},
		finishedAt,
	});
	await notifyGroup(deps.db, input.groupId, ["receiptScans"]);
}

export function failureCodeForError(
	error: unknown,
): "READER_UNAVAILABLE" | "READER_INVALID" | "READ_FAILED" {
	if (error instanceof z.ZodError) {
		return "READER_INVALID";
	}
	if (error instanceof AnthropicTransportError) {
		if (
			error.errorType === "invalid_shape" ||
			error.errorType === "missing_tool_use" ||
			error.errorType === "invalid_reading"
		) {
			return "READER_INVALID";
		}
		if (error.retryable || error.status === 401 || error.status === 403) {
			return "READER_UNAVAILABLE";
		}
	}
	return "READ_FAILED";
}
