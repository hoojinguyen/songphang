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
	approvalStatusFor,
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
	findGroupOwner,
	findTransactionRow,
	findUserById,
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
import type { EnqueueFn } from "../queue.js";
import {
	toAttachmentDto,
	validateTransactionAttachmentIds,
} from "./attachments.js";
import { assertLiveCategory } from "./categories.js";
import { notify, notifyBudgetWarnings } from "./notify.js";
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
						counted:
							existing.approvalStatus === "none" ||
							existing.approvalStatus === "approved",
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
function toApprovalDto(row: {
	approvalStatus: string;
	approvalDecidedByName: string | null;
	approvalDecidedAt: Date | null;
	approvalNote: string | null;
}) {
	return {
		status: row.approvalStatus,
		decidedByName: row.approvalDecidedByName ?? null,
		decidedAt: row.approvalDecidedAt?.toISOString() ?? null,
		note: row.approvalNote ?? null,
	};
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
			approval: toApprovalDto(row),
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
			approval: toApprovalDto(row),
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
		enqueue?: EnqueueFn;
	},
) {
	await lockGroup(executor, input.groupId);
	await getGroupAccess(executor, { ...input, minimumRole: "editor" });
	return createTransactionIn(executor, input);
}
async function notifyExpenseAdded(
	executor: DbExecutor,
	input: {
		groupId: string;
		groupName: string;
		actorUserId: string;
		actorName: string;
		transactionId: string;
		description: string;
		payers: Array<{ memberId: string }>;
		shares: Array<{ memberId: string; amount: number }>;
		now: Date;
	},
) {
	const shareByMember = new Map<string, number>();
	for (const payer of input.payers) shareByMember.set(payer.memberId, 0);
	for (const share of input.shares)
		shareByMember.set(share.memberId, share.amount);
	for (const [memberId, share] of shareByMember) {
		await notify(executor, {
			groupId: input.groupId,
			actorUserId: input.actorUserId,
			kind: "expense_added",
			payload: {
				kind: "expense_added",
				actorName: input.actorName,
				groupName: input.groupName,
				transactionId: input.transactionId,
				description: input.description,
				share,
			},
			toMemberIds: [memberId],
			now: input.now,
		});
	}
}
// Settlement confirmation supplies its own post-lock authorization; ordinary writes use createTransaction.
export async function createTransactionIn(
	executor: DbExecutor,
	input: {
		groupId: string;
		userId: string;
		request: CreateTransactionRequest;
		now: Date;
		enqueue?: EnqueueFn;
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
	const [group, owner, actor] = await Promise.all([
		findGroup(executor, input.groupId),
		findGroupOwner(executor, input.groupId),
		findUserById(executor, input.userId),
	]);
	if (group === null)
		throw new AppError(404, "NOT_FOUND", "Resource not found");
	const actorIsOwner = owner?.userId === input.userId;
	const approvalStatus = approvalStatusFor({
		type: request.type,
		amount: request.amount,
		threshold: group.approvalThreshold,
		actorIsOwner,
	});
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
		approvalStatus,
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
		counted: approvalStatus !== "pending",
	});
	const actorName = actor?.name ?? "";
	if (approvalStatus === "pending") {
		if (owner) {
			await notify(executor, {
				groupId: input.groupId,
				actorUserId: input.userId,
				kind: "approval_requested",
				payload: {
					kind: "approval_requested",
					actorName,
					groupName: group.name,
					transactionId: row.id,
					description: request.description,
					amount: request.amount,
				},
				toUserIds: [owner.userId],
				now: input.now,
				...(input.enqueue ? { enqueue: input.enqueue } : {}),
			});
		}
		return TransactionResponse.parse({ transaction, warnings });
	}
	if (request.type === "expense") {
		await notifyExpenseAdded(executor, {
			groupId: input.groupId,
			groupName: group.name,
			actorUserId: input.userId,
			actorName,
			transactionId: row.id,
			description: request.description,
			payers: request.payers,
			shares,
			now: input.now,
		});
	}
	await notifyBudgetWarnings(executor, {
		groupId: input.groupId,
		actorUserId: input.userId,
		actorName,
		groupName: group.name,
		warnings,
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
