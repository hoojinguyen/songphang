import { z } from "@hono/zod-openapi";
import {
	type CreateTransactionRequest,
	type ItemsPreviewIssue,
	type PreviewItemsRequest,
	PreviewItemsResponse,
	type PreviewTransactionRequest,
	PreviewTransactionResponse,
	TransactionDto,
	TransactionListItemDto,
	TransactionResponse,
	type TransactionsQuery,
	TransactionsResponse,
} from "@songphang/contract";
import {
	computeItemShares,
	computeItemsNetTotal,
	foldVietnamese,
	localDateRangeToUtc,
	receiptAdjustment,
} from "@songphang/core";
import {
	attachToTransaction,
	countAttachmentsForTransactions,
	countCommentsForTransactions,
	type DbExecutor,
	findGroup,
	findTransactionRow,
	insertActivity,
	insertTransaction,
	insertTransactionPayers,
	insertTransactionShares,
	listAttachmentsForTransactions,
	listGroupMembers,
	listOpenDisputesForTransactions,
	listTransactionPayers,
	listTransactionRows,
	listTransactionShares,
	lockGroup,
	type TransactionCursor,
	type TransactionFilters,
} from "@songphang/db";
import type { AppDeps } from "../app.js";
import { getGroupAccess } from "../auth/group-access.js";
import { AppError } from "../errors.js";
import {
	toAttachmentDto,
	validateTransactionAttachmentIds,
} from "./attachments.js";
import { assertLiveCategory } from "./categories.js";
import { calculateShares, normalizeTransaction } from "./transaction-input.js";
import { type ReplacedTransaction, transactionWarnings } from "./warnings.js";

const CURSOR_SCHEMA = z.object({ occurredAt: z.iso.datetime(), id: z.uuid() });
function decodeCursor(cursor: string | undefined): TransactionCursor | null {
	if (cursor === undefined) return null;
	try {
		if (!/^[A-Za-z0-9_-]+$/.test(cursor))
			throw new Error("Invalid cursor encoding");
		return CURSOR_SCHEMA.parse(
			JSON.parse(Buffer.from(cursor, "base64url").toString("utf8")),
		);
	} catch {
		throw new AppError(400, "VALIDATION_FAILED", "Invalid cursor");
	}
}
export async function previewTransaction(
	deps: AppDeps,
	groupId: string,
	request: PreviewTransactionRequest,
) {
	return deps.db.transaction(
		async (executor) => {
			let existingCategoryId: string | null = null;
			let replacing: ReplacedTransaction | undefined;
			if (request.transactionId !== undefined) {
				const existing = await findTransactionRow(
					executor,
					groupId,
					request.transactionId,
				);
				if (existing === null || existing.deletedAt !== null)
					throw new AppError(404, "NOT_FOUND", "Resource not found");
				if (
					existing.type === "expense" ||
					existing.type === "income" ||
					existing.type === "transfer"
				) {
					const existingPayers = await listTransactionPayers(
						executor,
						groupId,
						[existing.id],
					);
					replacing = {
						type: existing.type,
						amount: existing.amount,
						occurredAt: existing.occurredAt,
						payers: existingPayers,
					};
				}
				existingCategoryId = existing.categoryId;
			}
			if (
				request.categoryId !== null &&
				request.categoryId !== existingCategoryId
			)
				await assertLiveCategory(executor, groupId, request.categoryId);
			const [shares, warnings] = await Promise.all([
				calculateShares(executor, groupId, request),
				transactionWarnings(executor, {
					groupId,
					request,
					applied: false,
					now: deps.now(),
					...(replacing ? { replacing } : {}),
				}),
			]);
			return PreviewTransactionResponse.parse({ shares, warnings });
		},
		{ isolationLevel: "repeatable read", accessMode: "read only" },
	);
}
export async function mapTransactions(
	executor: DbExecutor,
	groupId: string,
	rows: Awaited<ReturnType<typeof listTransactionRows>>,
	viewerUserId: string | null = null,
) {
	const ids = rows.map((row) => row.id);
	const [payers, shares, attachmentRows, commentCounts, disputes] =
		await Promise.all([
			listTransactionPayers(executor, groupId, ids),
			listTransactionShares(executor, groupId, ids),
			listAttachmentsForTransactions(executor, groupId, ids),
			countCommentsForTransactions(executor, groupId, ids),
			listOpenDisputesForTransactions(executor, groupId, ids),
		]);
	return rows.map((row) => {
		const dispute = disputes.get(row.id);
		return TransactionDto.parse({
			...row,
			occurredAt: row.occurredAt.toISOString(),
			createdAt: row.createdAt.toISOString(),
			updatedAt: row.updatedAt.toISOString(),
			deletedAt: row.deletedAt?.toISOString() ?? null,
			commentCount: commentCounts.get(row.id) ?? 0,
			dispute: dispute
				? {
						id: dispute.id,
						reason: dispute.reason,
						openedByName: dispute.openedByName,
						openedAt: dispute.openedAt.toISOString(),
						mine: viewerUserId !== null && dispute.openedBy === viewerUserId,
					}
				: null,
			payers: payers.filter((payer) => payer.transactionId === row.id),
			shares: shares.filter((share) => share.transactionId === row.id),
			attachments: attachmentRows
				.filter((attachment) => attachment.transactionId === row.id)
				.map(toAttachmentDto),
		});
	});
}

async function mapTransactionListItems(
	executor: DbExecutor,
	groupId: string,
	rows: Awaited<ReturnType<typeof listTransactionRows>>,
	viewerUserId: string | null = null,
) {
	const ids = rows.map((row) => row.id);
	const [payers, shares, attachmentCounts, commentCounts, disputes] =
		await Promise.all([
			listTransactionPayers(executor, groupId, ids),
			listTransactionShares(executor, groupId, ids),
			countAttachmentsForTransactions(executor, groupId, ids),
			countCommentsForTransactions(executor, groupId, ids),
			listOpenDisputesForTransactions(executor, groupId, ids),
		]);
	return rows.map((row) => {
		const dispute = disputes.get(row.id);
		return TransactionListItemDto.parse({
			...row,
			occurredAt: row.occurredAt.toISOString(),
			createdAt: row.createdAt.toISOString(),
			updatedAt: row.updatedAt.toISOString(),
			deletedAt: row.deletedAt?.toISOString() ?? null,
			commentCount: commentCounts.get(row.id) ?? 0,
			dispute: dispute
				? {
						id: dispute.id,
						reason: dispute.reason,
						openedByName: dispute.openedByName,
						openedAt: dispute.openedAt.toISOString(),
						mine: viewerUserId !== null && dispute.openedBy === viewerUserId,
					}
				: null,
			payers: payers.filter((payer) => payer.transactionId === row.id),
			shares: shares.filter((share) => share.transactionId === row.id),
			attachmentCount: attachmentCounts.get(row.id) ?? 0,
		});
	});
}
export async function createTransaction(
	executor: DbExecutor,
	input: {
		groupId: string;
		userId: string;
		request: CreateTransactionRequest;
		now: Date;
	},
) {
	await lockGroup(executor, input.groupId);
	await getGroupAccess(executor, { ...input, minimumRole: "editor" });
	return createTransactionIn(executor, input);
}
// Settlement confirmation supplies its own post-lock authorization; ordinary writes use createTransaction.
export async function createTransactionIn(
	executor: DbExecutor,
	input: {
		groupId: string;
		userId: string;
		request: CreateTransactionRequest;
		now: Date;
	},
) {
	const shares = await calculateShares(executor, input.groupId, input.request);
	const request = normalizeTransaction(input.request);
	await assertLiveCategory(executor, input.groupId, request.categoryId);
	const attachmentIds = input.request.attachmentIds ?? [];
	await validateTransactionAttachmentIds(
		executor,
		input.groupId,
		attachmentIds,
		null,
	);
	const group = await findGroup(executor, input.groupId);
	if (group === null)
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	const row = await insertTransaction(executor, {
		groupId: input.groupId,
		type: request.type,
		description: request.description,
		descriptionSearch: foldVietnamese(request.description),
		amount: request.amount,
		currency: group.currency,
		occurredAt: new Date(request.occurredAt),
		category: request.category,
		categoryId: request.categoryId,
		splitMethod: request.split.method,
		splitInput: request.split,
		createdBy: input.userId,
		updatedBy: input.userId,
		createdAt: input.now,
		updatedAt: input.now,
	});
	await insertTransactionPayers(
		executor,
		request.payers.map((payer) => ({ ...payer, transactionId: row.id })),
	);
	await insertTransactionShares(
		executor,
		shares.map((share) => ({ ...share, transactionId: row.id })),
	);
	await attachToTransaction(executor, input.groupId, row.id, attachmentIds);
	await insertActivity(executor, {
		groupId: input.groupId,
		actorUserId: input.userId,
		action: "create",
		entityType: "transaction",
		entityId: row.id,
		summary: request.description,
		after: { ...request, shares },
		createdAt: input.now,
	});
	const stored = await findTransactionRow(executor, input.groupId, row.id);
	if (stored === null) throw new Error("Inserted transaction not found");
	const [transaction] = await mapTransactions(
		executor,
		input.groupId,
		[stored],
		input.userId,
	);
	const warnings = await transactionWarnings(executor, {
		groupId: input.groupId,
		request: input.request,
		applied: true,
		now: input.now,
	});
	return TransactionResponse.parse({ transaction, warnings });
}
function buildFilters(query: TransactionsQuery): TransactionFilters {
	const range = localDateRangeToUtc(query.from, query.to);
	const searchPattern =
		query.q === undefined
			? undefined
			: `%${foldVietnamese(query.q).replace(/[\\%_]/g, "\\$&")}%`;
	return {
		...(searchPattern === undefined ? {} : { searchPattern }),
		...(query.memberId === undefined ? {} : { memberId: query.memberId }),
		...(query.category === undefined ? {} : { category: query.category }),
		...(query.categoryId === undefined ? {} : { categoryId: query.categoryId }),
		...(query.uncategorized === "true" ? { uncategorized: true } : {}),
		...(query.spendingOnly === "true" ? { spendingOnly: true } : {}),
		...(query.type === undefined ? {} : { type: query.type }),
		...(range.start === undefined ? {} : { start: range.start }),
		...(range.endExclusive === undefined
			? {}
			: { endExclusive: range.endExclusive }),
	};
}
export async function listTransactions(
	deps: AppDeps,
	groupId: string,
	query: TransactionsQuery,
	viewerUserId: string | null = null,
) {
	const filters = buildFilters(query);
	return deps.db.transaction(
		async (executor) => {
			const rows = await listTransactionRows(executor, {
				groupId,
				cursor: decodeCursor(query.cursor),
				limit: query.limit + 1,
				filters,
			});
			const page = rows.slice(0, query.limit);
			const last = page.at(-1);
			const nextCursor =
				rows.length > query.limit && last !== undefined
					? Buffer.from(
							JSON.stringify({
								occurredAt: last.occurredAt.toISOString(),
								id: last.id,
							}),
						).toString("base64url")
					: null;
			return TransactionsResponse.parse({
				transactions: await mapTransactionListItems(
					executor,
					groupId,
					page,
					viewerUserId,
				),
				nextCursor,
			});
		},
		{ isolationLevel: "repeatable read", accessMode: "read only" },
	);
}

const MAX_TRANSACTION_AMOUNT = 999_999_999_999;

export async function previewItemsSplit(
	deps: AppDeps,
	groupId: string,
	request: PreviewItemsRequest,
): Promise<PreviewItemsResponse> {
	return deps.db.transaction(
		async (executor) => {
			const members = await listGroupMembers(executor, groupId);
			const memberIds = [
				...new Set(request.items.flatMap((item) => item.memberIds)),
			];
			if (memberIds.some((id) => !members.some((m) => m.id === id))) {
				throw new AppError(
					400,
					"MEMBER_NOT_IN_GROUP",
					"Member does not belong to group",
				);
			}
			if (
				memberIds.some(
					(id) => members.find((m) => m.id === id)?.kind === "fund",
				)
			) {
				throw new AppError(
					422,
					"FUND_CANNOT_SHARE",
					"Fund member cannot bear a share",
				);
			}

			const computedAmount = computeItemsNetTotal(
				request.items,
				request.extras,
			);
			const target =
				request.targetTotal === undefined
					? {}
					: {
							targetAdjustment: receiptAdjustment(
								request.targetTotal,
								computedAmount,
							),
						};
			const issues: ItemsPreviewIssue[] = [];
			const unassignedIndex = request.items.findIndex(
				(item) => item.memberIds.length === 0,
			);
			if (unassignedIndex >= 0) {
				issues.push({ code: "ITEM_UNASSIGNED", itemIndex: unassignedIndex });
			}
			if (computedAmount < 1 || computedAmount > MAX_TRANSACTION_AMOUNT) {
				issues.push({ code: "INVALID_TOTAL" });
			}
			if (issues.length > 0) {
				return PreviewItemsResponse.parse({
					computedAmount,
					issues,
					...target,
				});
			}

			const result = computeItemShares(
				computedAmount,
				{
					method: "items",
					items: request.items,
					extras: request.extras,
				},
				members.map((m) => m.id),
			);
			if (!result.ok) {
				if (result.code === "ITEM_UNASSIGNED") {
					return PreviewItemsResponse.parse({
						computedAmount,
						issues: [{ code: "ITEM_UNASSIGNED", itemIndex: result.itemIndex }],
						...target,
					});
				}
				return PreviewItemsResponse.parse({
					computedAmount,
					issues: [{ code: "INVALID_TOTAL" }],
					...target,
				});
			}

			return PreviewItemsResponse.parse({
				computedAmount,
				shares: result.shares,
				issues: [],
				...target,
			});
		},
		{ isolationLevel: "repeatable read", accessMode: "read only" },
	);
}
