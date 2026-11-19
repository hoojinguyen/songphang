import { AnthropicTransportError } from "@songphang/ai";
import { quotaWindowStarts } from "@songphang/core";
import { claimAiCall, linkAiCallToScan, reserveAiCall } from "@songphang/db";
import type { ReceiptReader } from "../ai/receipt-reader.js";
import type { WorkerDeps } from "../queue.js";
import {
	applyReadingOutcome,
	failAndNotify,
	failureCodeForError,
	finishFailedAttempt,
} from "./read-receipt-outcome.js";

export async function handleFailedAttempt(
	deps: WorkerDeps,
	input: {
		scanId: string;
		groupId: string;
		userId: string;
		reader: ReceiptReader;
		imageBytes: Buffer;
		mimeType: "image/jpeg" | "image/png" | "image/webp";
		sha256: string;
		firstReservationId: string;
		error: unknown;
	},
): Promise<void> {
	await finishFailedAttempt(deps, input.firstReservationId, {
		error: input.error,
	});

	if (
		!(input.error instanceof AnthropicTransportError) ||
		!input.error.retryable
	) {
		await failAndNotify(
			deps,
			input.groupId,
			input.scanId,
			failureCodeForError(input.error),
		);
		return;
	}

	const retryNow = deps.now();
	const retryRes = await reserveAiCall(deps.db, {
		purpose: "receipt",
		userId: input.userId,
		groupId: input.groupId,
		limits: {
			userDaily: deps.config.aiReceiptsPerUserPerDay,
			monthTotal: deps.config.aiCallsPerMonth,
		},
		now: retryNow,
	});
	if (retryRes.status !== "ok") {
		await failAndNotify(
			deps,
			input.groupId,
			input.scanId,
			"READER_UNAVAILABLE",
		);
		return;
	}

	await linkAiCallToScan(deps.db, {
		id: retryRes.reservationId,
		receiptScanId: input.scanId,
	});
	const retryClaim = await claimAiCall(deps.db, {
		id: retryRes.reservationId,
		purpose: "receipt",
		userId: input.userId,
		groupId: input.groupId,
		receiptScanId: input.scanId,
		minCreatedAt: quotaWindowStarts(retryNow).dayStart,
		startedAt: retryNow,
	});
	if (!retryClaim) {
		await finishFailedAttempt(deps, retryRes.reservationId);
		await failAndNotify(
			deps,
			input.groupId,
			input.scanId,
			"READER_UNAVAILABLE",
		);
		return;
	}

	try {
		const output = await input.reader.readReceipt({
			imageBytes: input.imageBytes,
			mimeType: input.mimeType,
			sha256: input.sha256,
		});
		await applyReadingOutcome(deps, {
			scanId: input.scanId,
			groupId: input.groupId,
			reservationId: retryRes.reservationId,
			output,
		});
	} catch (retryError) {
		await finishFailedAttempt(deps, retryRes.reservationId, {
			error: retryError,
		});
		await failAndNotify(
			deps,
			input.groupId,
			input.scanId,
			failureCodeForError(retryError),
		);
	}
}
