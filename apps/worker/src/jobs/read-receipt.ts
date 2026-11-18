import { createHash } from "node:crypto";
import { JOB_NAMES, ReadReceiptPayload } from "@songphang/contract";
import { quotaWindowStarts } from "@songphang/core";
import {
	claimAiCall,
	failStaleProcessingScans,
	findAiCall,
	findAttachment,
	findReceiptScanById,
	finishStaleStartedAiCalls,
	markReceiptScanProcessing,
} from "@songphang/db";
import type { PgBoss } from "pg-boss";
import { z } from "zod";
import { selectReceiptReader } from "../ai/receipt-reader.js";
import { notifyGroup } from "../notify.js";
import { registerJob, type WorkerDeps } from "../queue.js";
import {
	applyReadingOutcome,
	failAndNotify,
	finishFailedAttempt,
} from "./read-receipt-outcome.js";
import { handleFailedAttempt } from "./read-receipt-retry.js";

const STALE_SCAN_AGE_MS = 90_000;
const IMAGE_MIME_SCHEMA = z.enum(["image/jpeg", "image/png", "image/webp"]);

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
			await finishFailedAttempt(deps, existing.id);
			await failAndNotify(deps, scan.groupId, scan.id, "READ_FAILED");
			return;
		}
		if (existing && existing.state === "reserved") {
			await finishFailedAttempt(deps, existing.id, { model: "expired" });
			await failAndNotify(deps, scan.groupId, scan.id, "READER_UNAVAILABLE");
			return;
		}
		await failAndNotify(deps, scan.groupId, scan.id, "READ_FAILED");
		return;
	}

	const marked = await markReceiptScanProcessing(deps.db, scan.id);
	if (!marked) {
		await finishFailedAttempt(deps, claimed.id);
		return;
	}

	const reader =
		deps.receiptReader !== undefined
			? deps.receiptReader
			: selectReceiptReader(deps.config);
	if (!reader) {
		await finishFailedAttempt(deps, claimed.id, { model: "disabled" });
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
		await finishFailedAttempt(deps, claimed.id);
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
