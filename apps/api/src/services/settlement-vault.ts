import { z } from "@hono/zod-openapi";
import {
	PaymentChannel,
	SettlementStatus,
	SettlementVaultItemDto,
	type SettlementVaultQuery,
	SettlementVaultResponse,
} from "@songphang/contract";
import {
	findLatestSettlementCycle,
	findSettlementCycle,
	listAttachmentsForTransactions,
	listSettlementVaultKeys,
	listTransactionPayers,
	listTransactionShares,
	listVaultRequestsByIds,
	listVaultTransfersByIds,
	querySettlementVaultSummary,
	type VaultCursor,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { AppError } from "../errors.js";
import { toAttachmentDto } from "./attachments.js";

const VAULT_CURSOR_SCHEMA = z.object({
	isPending: z.boolean(),
	sortAt: z.iso.datetime(),
	kind: z.enum(["transfer", "request"]),
	id: z.uuid(),
});

function decodeVaultCursor(cursor: string | undefined): VaultCursor | null {
	if (cursor === undefined) return null;
	try {
		if (!/^[A-Za-z0-9_-]+$/.test(cursor)) {
			throw new Error("Invalid cursor encoding");
		}
		return VAULT_CURSOR_SCHEMA.parse(
			JSON.parse(Buffer.from(cursor, "base64url").toString("utf8")),
		);
	} catch {
		throw new AppError(400, "VALIDATION_FAILED", "Invalid cursor");
	}
}

function encodeVaultCursor(entry: {
	isPending: boolean;
	sortAt: Date;
	kind: "transfer" | "request";
	id: string;
}): string {
	return Buffer.from(
		JSON.stringify({
			isPending: entry.isPending,
			sortAt: entry.sortAt.toISOString(),
			kind: entry.kind,
			id: entry.id,
		}),
	).toString("base64url");
}

export async function getSettlementVault(
	deps: AppDeps,
	groupId: string,
	query: SettlementVaultQuery,
) {
	const cursor = decodeVaultCursor(query.cursor);
	return deps.db.transaction(
		async (executor) => {
			let transferCycle:
				| { kind: "all" }
				| { kind: "current" }
				| { kind: "cycle"; id: string } = { kind: "all" };
			let requestCycle:
				| { kind: "all" }
				| { kind: "current"; afterClosedAt: Date | null }
				| { kind: "cycle"; startedAt: Date; closedAt: Date } = { kind: "all" };

			if (query.cycleId === "current") {
				const latest = await findLatestSettlementCycle(executor, groupId);
				transferCycle = { kind: "current" };
				requestCycle = {
					kind: "current",
					afterClosedAt: latest?.closedAt ?? null,
				};
			} else if (query.cycleId !== undefined) {
				const cycle = await findSettlementCycle(
					executor,
					groupId,
					query.cycleId,
				);
				if (cycle === null) {
					throw new AppError(404, "NOT_FOUND", "Resource not found");
				}
				transferCycle = { kind: "cycle", id: cycle.id };
				requestCycle = {
					kind: "cycle",
					startedAt: cycle.startedAt,
					closedAt: cycle.closedAt,
				};
			}

			const [summary, keys] = await Promise.all([
				querySettlementVaultSummary(executor, {
					groupId,
					transferCycle,
					requestCycle,
				}),
				listSettlementVaultKeys(executor, {
					groupId,
					filter: query.filter,
					transferCycle,
					requestCycle,
					cursor,
					limit: query.limit + 1,
				}),
			]);

			const page = keys.slice(0, query.limit);
			const transferIds = page
				.filter((entry) => entry.kind === "transfer")
				.map((entry) => entry.id);
			const requestIds = page
				.filter((entry) => entry.kind === "request")
				.map((entry) => entry.id);

			const [transfers, payers, shares, attachmentRows, requests] =
				await Promise.all([
					listVaultTransfersByIds(executor, groupId, transferIds),
					listTransactionPayers(executor, groupId, transferIds),
					listTransactionShares(executor, groupId, transferIds),
					listAttachmentsForTransactions(executor, groupId, transferIds),
					listVaultRequestsByIds(executor, groupId, requestIds),
				]);

			const transferById = new Map(transfers.map((row) => [row.id, row]));
			const requestById = new Map(requests.map((row) => [row.request.id, row]));

			const items: SettlementVaultItemDto[] = [];
			for (const entry of page) {
				if (entry.kind === "transfer") {
					const transfer = transferById.get(entry.id);
					if (!transfer) continue;
					const fromMemberId = payers.find(
						(payer) => payer.transactionId === transfer.id,
					)?.memberId;
					const toMemberId = shares.find(
						(share) => share.transactionId === transfer.id,
					)?.memberId;
					if (!fromMemberId || !toMemberId) continue;
					items.push(
						SettlementVaultItemDto.parse({
							id: transfer.id,
							kind: "transfer",
							status: "confirmed",
							transactionId: transfer.id,
							settlementRequestId: transfer.settlementRequestId ?? null,
							fromMemberId,
							toMemberId,
							amount: transfer.amount,
							channel: PaymentChannel.nullable().parse(
								transfer.paymentChannel ?? transfer.requestChannel ?? null,
							),
							note: transfer.paymentNote ?? transfer.requestNote ?? null,
							description: transfer.description,
							attachments: attachmentRows
								.filter(
									(attachment) => attachment.transactionId === transfer.id,
								)
								.slice(0, 3)
								.map(toAttachmentDto),
							createdBy:
								transfer.createdById && transfer.createdByName
									? { id: transfer.createdById, name: transfer.createdByName }
									: null,
							resolvedBy:
								transfer.resolvedById && transfer.resolvedByName
									? { id: transfer.resolvedById, name: transfer.resolvedByName }
									: null,
							occurredAt: transfer.occurredAt.toISOString(),
							resolvedAt: transfer.resolvedAt?.toISOString() ?? null,
							cycleId: transfer.cycleId ?? null,
						}),
					);
				} else {
					const row = requestById.get(entry.id);
					if (!row) continue;
					const req = row.request;
					items.push(
						SettlementVaultItemDto.parse({
							id: req.id,
							kind: "request",
							status: SettlementStatus.parse(req.status),
							transactionId: null,
							settlementRequestId: req.id,
							fromMemberId: req.fromMemberId,
							toMemberId: req.toMemberId,
							amount: req.amount,
							channel: PaymentChannel.nullable().parse(req.channel ?? null),
							note: req.note ?? null,
							description: null,
							attachments: row.proofAttachment
								? [toAttachmentDto(row.proofAttachment)]
								: [],
							createdBy:
								req.createdBy && row.creatorName
									? { id: req.createdBy, name: row.creatorName }
									: null,
							resolvedBy:
								req.resolvedBy && row.resolverName
									? { id: req.resolvedBy, name: row.resolverName }
									: null,
							occurredAt: req.createdAt.toISOString(),
							resolvedAt: req.resolvedAt?.toISOString() ?? null,
							cycleId: null,
						}),
					);
				}
			}

			const last = page.at(-1);
			return SettlementVaultResponse.parse({
				items,
				summary,
				nextCursor:
					keys.length > query.limit && last ? encodeVaultCursor(last) : null,
			});
		},
		{ isolationLevel: "repeatable read", accessMode: "read only" },
	);
}
