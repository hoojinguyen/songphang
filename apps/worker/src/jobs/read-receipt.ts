import { createHash } from "node:crypto";
import { AnthropicTransportError } from "@songphang/ai";
import { JOB_NAMES, ReadReceiptPayload } from "@songphang/contract";
import { checkReceipt, quotaWindowStarts } from "@songphang/core";
import {
	claimAiCall,
	failStaleProcessingScans,
	findAiCall,
	findAttachment,
	findReceiptScanById,
	finishReceiptScanDone,
	finishReceiptScanFailed,
	finishStaleStartedAiCalls,
	linkAiCallToScan,
	markReceiptScanProcessing,
	recordAiCall,
	reserveAiCall,
} from "@songphang/db";
import type { PgBoss } from "pg-boss";
import { z } from "zod";
import {
	type ReceiptReader,
	type ReceiptReaderOutput,
	selectReceiptReader,
} from "../ai/receipt-reader.js";
import { notifyGroup } from "../notify.js";
import { registerJob, type WorkerDeps } from "../queue.js";

const STALE_SCAN_AGE_MS = 90_000;
const IMAGE_MIME_SCHEMA = z.enum(["image/jpeg", "image/png", "image/webp"]);

async function failAndNotify(
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

async function applyReadingOutcome(
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

function failureCodeForError(
	error: unknown,
): "READER_UNAVAILABLE" | "READER_INVALID" | "READ_FAILED" {
	if (error instanceof z.ZodError) {
		return "READER_INVALID";
	}
	if (error instanceof AnthropicTransportError) {
		if (
			error.errorType === "invalid_shape" ||
			error.errorType === "missing_tool_use"
		) {
			return "READER_INVALID";
		}
		if (error.retryable || error.status === 401 || error.status === 403) {
			return "READER_UNAVAILABLE";
		}
	}
	return "READ_FAILED";
}

async function handleFailedAttempt(
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
	const model = deps.config.aiModel ?? "";
	await recordAiCall(deps.db, {
		id: input.firstReservationId,
		model,
		inputTokens: 0,
		outputTokens: 0,
		ok: false,
		finishedAt: deps.now(),
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
		await recordAiCall(deps.db, {
			id: retryRes.reservationId,
			model,
			inputTokens: 0,
			outputTokens: 0,
			ok: false,
			finishedAt: deps.now(),
		});
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
		await recordAiCall(deps.db, {
			id: retryRes.reservationId,
			model,
			inputTokens: 0,
			outputTokens: 0,
			ok: false,
			finishedAt: deps.now(),
		});
		await failAndNotify(
			deps,
			input.groupId,
			input.scanId,
			failureCodeForError(retryError),
		);
	}
}

export async function runReadReceiptJob(
	data: ReadReceiptPayload,
	deps: WorkerDeps,
): Promise<void> {
	const scan = await findReceiptScanById(deps.db, data.scanId);
	if (!scan || scan.status === "done" || scan.status === "failed") {
		return;
	}
	if (!scan.createdBy) {
		await failAndNotify(deps, scan.groupId, scan.id, "READ_FAILED");
		return;
	}

	const now = deps.now();
	const { dayStart } = quotaWindowStarts(now);
	const claimed = await claimAiCall(deps.db, {
		id: data.reservationId,
		purpose: "receipt",
		userId: scan.createdBy,
		groupId: scan.groupId,
		receiptScanId: scan.id,
		minCreatedAt: dayStart,
		startedAt: now,
	});
	if (!claimed) {
		const existing = await findAiCall(deps.db, data.reservationId);
		if (existing && existing.state === "started") {
			await recordAiCall(deps.db, {
				id: existing.id,
				model: deps.config.aiModel ?? "",
				inputTokens: 0,
				outputTokens: 0,
				ok: false,
				finishedAt: deps.now(),
			});
			await failAndNotify(deps, scan.groupId, scan.id, "READ_FAILED");
			return;
		}
		if (existing && existing.state === "reserved") {
			await recordAiCall(deps.db, {
				id: existing.id,
				model: "expired",
				inputTokens: 0,
				outputTokens: 0,
				ok: false,
				finishedAt: deps.now(),
			});
			await failAndNotify(deps, scan.groupId, scan.id, "READER_UNAVAILABLE");
			return;
		}
		await failAndNotify(deps, scan.groupId, scan.id, "READ_FAILED");
		return;
	}

	const marked = await markReceiptScanProcessing(deps.db, scan.id);
	if (!marked) {
		await recordAiCall(deps.db, {
			id: claimed.id,
			model: deps.config.aiModel ?? "",
			inputTokens: 0,
			outputTokens: 0,
			ok: false,
			finishedAt: deps.now(),
		});
		return;
	}

	const reader =
		deps.receiptReader !== undefined
			? deps.receiptReader
			: selectReceiptReader(deps.config);
	if (!reader) {
		await recordAiCall(deps.db, {
			id: claimed.id,
			model: "disabled",
			inputTokens: 0,
			outputTokens: 0,
			ok: false,
			finishedAt: deps.now(),
		});
		await failAndNotify(deps, scan.groupId, scan.id, "READER_UNAVAILABLE");
		return;
	}

	const attachment = await findAttachment(
		deps.db,
		scan.groupId,
		scan.attachmentId,
	);
	const mimeParsed = IMAGE_MIME_SCHEMA.safeParse(attachment?.contentType);
	const bytes = attachment
		? await deps.fileStore.get(attachment.storageKey)
		: null;
	if (!attachment || !mimeParsed.success || !bytes) {
		await recordAiCall(deps.db, {
			id: claimed.id,
			model: deps.config.aiModel ?? "",
			inputTokens: 0,
			outputTokens: 0,
			ok: false,
			finishedAt: deps.now(),
		});
		await failAndNotify(deps, scan.groupId, scan.id, "READ_FAILED");
		return;
	}

	const imageBytes = Buffer.from(bytes);
	const sha256 = createHash("sha256").update(imageBytes).digest("hex");

	try {
		const output = await reader.readReceipt({
			imageBytes,
			mimeType: mimeParsed.data,
			sha256,
		});
		await applyReadingOutcome(deps, {
			scanId: scan.id,
			groupId: scan.groupId,
			reservationId: data.reservationId,
			output,
		});
	} catch (error) {
		await handleFailedAttempt(deps, {
			scanId: scan.id,
			groupId: scan.groupId,
			userId: scan.createdBy,
			reader,
			imageBytes,
			mimeType: mimeParsed.data,
			sha256,
			firstReservationId: data.reservationId,
			error,
		});
	}
}

export async function recoverStaleScans(
	deps: WorkerDeps,
	maxAgeMs: number = STALE_SCAN_AGE_MS,
): Promise<number> {
	const now = deps.now();
	const cutoff = new Date(now.getTime() - maxAgeMs);
	const recovered = await deps.db.transaction(async (executor) => {
		const stale = await failStaleProcessingScans(executor, {
			cutoff,
			finishedAt: now,
			errorCode: "READ_FAILED",
		});
		await finishStaleStartedAiCalls(executor, {
			scanIds: stale.map((item) => item.id),
			finishedAt: now,
		});
		return stale;
	});
	const groupIds = [...new Set(recovered.map((item) => item.groupId))];
	for (const groupId of groupIds) {
		await notifyGroup(deps.db, groupId, ["receiptScans"]);
	}
	return recovered.length;
}

export async function registerReadReceiptJob(
	boss: PgBoss,
	deps: WorkerDeps,
): Promise<void> {
	await registerJob(
		boss,
		JOB_NAMES.readReceipt,
		ReadReceiptPayload,
		async (data, workerDeps) => {
			await runReadReceiptJob(data, workerDeps);
		},
		deps,
	);
}
