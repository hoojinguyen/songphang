import { z } from "@hono/zod-openapi";
import {
	type CreateReceiptScanRequest,
	JOB_NAMES,
	ReceiptReading,
	ReceiptScanDto,
	ReceiptScanResponse,
	ReceiptScanStatus,
} from "@songphang/contract";
import {
	findAttachment,
	findGroupAccess,
	findReceiptScan,
	findReceiptScanByAttachment,
	insertReceiptScan,
	linkAiCallToScan,
	lockGroup,
	type ReceiptScanRow,
	reserveAiCall,
} from "@songphang/db";
import { uuidv7 } from "uuidv7";
import type { AppDeps } from "../app.js";
import { AppError } from "../errors.js";
import { runIdempotent } from "../idempotency.js";

function toReceiptScanDto(row: ReceiptScanRow): ReceiptScanDto {
	return ReceiptScanDto.parse({
		id: row.id,
		attachmentId: row.attachmentId,
		status: ReceiptScanStatus.parse(row.status),
		reading: row.result ? ReceiptReading.parse(row.result.reading) : null,
		computed: row.result ? row.result.computed : null,
		flags: row.result ? row.result.flags : [],
		errorCode: row.errorCode ?? null,
		createdAt: row.createdAt.toISOString(),
	});
}

export async function createReceiptScan(
	deps: AppDeps,
	input: {
		groupId: string;
		userId: string;
		idempotencyKey: string;
		requestHash: string;
		request: CreateReceiptScanRequest;
	},
): Promise<{ status: 200 | 201; body: ReceiptScanResponse }> {
	if (!deps.config.aiProvider) {
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	}
	let created = false;
	const result = await runIdempotent(
		deps,
		{
			userId: input.userId,
			key: input.idempotencyKey,
			requestHash: input.requestHash,
			onCommitted: () => {
				if (created) {
					deps.events.publishChanged(input.groupId, ["receiptScans"]);
				}
			},
		},
		async (transaction) => {
			await lockGroup(transaction, input.groupId);
			const access = await findGroupAccess(
				transaction,
				input.groupId,
				input.userId,
			);
			if (!access) {
				throw new AppError(404, "NOT_FOUND", "Group not found");
			}
			if (access.role !== "owner" && access.role !== "editor") {
				throw new AppError(403, "FORBIDDEN", "Editor role required");
			}

			const attachment = await findAttachment(
				transaction,
				input.groupId,
				input.request.attachmentId,
			);
			if (!attachment) {
				throw new AppError(
					400,
					"VALIDATION_FAILED",
					"Attachment does not belong to this group",
				);
			}

			const existing = await findReceiptScanByAttachment(
				transaction,
				input.groupId,
				attachment.id,
			);
			if (existing) {
				return {
					status: 200,
					body: ReceiptScanResponse.parse({
						scan: toReceiptScanDto(existing),
					}),
				};
			}

			const now = deps.now();
			const reservation = await reserveAiCall(transaction, {
				purpose: "receipt",
				userId: input.userId,
				groupId: input.groupId,
				limits: {
					userDaily: deps.config.aiReceiptsPerUserPerDay,
					monthTotal: deps.config.aiCallsPerMonth,
				},
				now,
			});
			if (reservation.status !== "ok") {
				throw new AppError(
					429,
					"AI_QUOTA_EXCEEDED",
					"AI receipt reading quota exceeded",
					{ scope: reservation.status === "user_limit" ? "user" : "month" },
				);
			}

			const scan = await insertReceiptScan(transaction, {
				id: uuidv7(),
				groupId: input.groupId,
				attachmentId: attachment.id,
				createdBy: input.userId,
				createdAt: now,
			});
			await linkAiCallToScan(transaction, {
				id: reservation.reservationId,
				receiptScanId: scan.id,
			});
			await deps.enqueue(transaction, JOB_NAMES.readReceipt, {
				scanId: scan.id,
				reservationId: reservation.reservationId,
			});
			created = true;
			return {
				status: 201,
				body: ReceiptScanResponse.parse({ scan: toReceiptScanDto(scan) }),
			};
		},
	);

	return {
		status: result.status === 200 ? 200 : 201,
		body: ReceiptScanResponse.parse(result.body),
	};
}

export async function getReceiptScan(
	deps: AppDeps,
	input: { groupId: string; scanId: string },
): Promise<ReceiptScanResponse> {
	if (!z.uuid().safeParse(input.scanId).success) {
		throw new AppError(404, "NOT_FOUND", "Receipt scan not found");
	}
	const scan = await findReceiptScan(deps.db, input.groupId, input.scanId);
	if (!scan) {
		throw new AppError(404, "NOT_FOUND", "Receipt scan not found");
	}
	return ReceiptScanResponse.parse({ scan: toReceiptScanDto(scan) });
}
