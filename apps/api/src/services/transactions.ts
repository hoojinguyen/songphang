import { z } from "@hono/zod-openapi";
import {
	type CreateTransactionRequest,
	type ExtrasPreviewIssue,
	type ItemsPreviewIssue,
	type ItemsSplitExtra,
	type PreviewExtrasRequest,
	PreviewExtrasResponse,
	type PreviewItemsRequest,
	PreviewItemsResponse,
	type PreviewTransactionRequest,
	PreviewTransactionResponse,
	type ShareDto,
	type SplitInput,
	TransactionDto,
	TransactionListItemDto,
	TransactionResponse,
	type TransactionsQuery,
	TransactionsResponse,
	type TransactionWarning,
} from "@songphang/contract";
import {
	approvalStatusFor,
	computeItemShares,
	computeItemsNetTotal,
	computePercentExtraAmount,
	computeShares,
	foldVietnamese,
	localDateRangeToUtc,
	nextEditApprovalStatusFor,
	receiptAdjustment,
	toVietnamDate,
} from "@songphang/core";
import {
	attachToTransaction,
	countCommentsForTransactions,
	type DbExecutor,
	findGroup,
	findGroupAccess,
	findGroupOwner,
	findRecurringExpense,
	findSettlementCycle,
	findTransactionRow,
	findUserById,
	insertActivity,
	insertTransaction,
	insertTransactionPayers,
	insertTransactionShares,
	listAttachmentSummariesForTransactions,
	listAttachmentsForTransactions,
	listGroupMembers,
	listOpenDisputesForTransactions,
	listTransactionPayers,
	listTransactionRows,
	listTransactionShares,
	lockGroup,
	type TransactionCursor,
	type TransactionFilters,
	updateRecurringExpense,
	updateTransactionRow,
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
import { assertGroupRowNotArchived } from "./group-guards.js";
import { notify, notifyBudgetWarnings } from "./notify.js";
import { createRecurringExpenseIn } from "./recurring-expenses.js";
import { calculateShares, normalizeTransaction } from "./transaction-input.js";
import { type ReplacedTransaction, transactionWarnings } from "./warnings.js";

const CURSOR_SCHEMA = z.object({ occurredAt: z.iso.datetime(), id: z.uuid() });
export function decodeTransactionCursor(
	cursor: string | undefined,
): TransactionCursor | null {
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

export function encodeTransactionCursor(row: {
	occurredAt: Date;
	id: string;
}): string {
	return Buffer.from(
		JSON.stringify({
			occurredAt: row.occurredAt.toISOString(),
			id: row.id,
		}),
	).toString("base64url");
}

export function buildSearchPattern(q: string | undefined): string | undefined {
	if (q === undefined) return undefined;
	return `%${foldVietnamese(q).replace(/[\\%_]/g, "\\$&")}%`;
}

export function computeMyDelta(input: {
	type: string;
	deletedAt: Date | null;
	approvalStatus: string;
	viewerMemberId: string | null;
	payers: ReadonlyArray<{ memberId: string; amount: number }>;
	shares: ReadonlyArray<{ memberId: string; amount: number }>;
}): number | null {
	if (input.viewerMemberId === null || input.deletedAt !== null) return null;
	if (input.approvalStatus !== "none" && input.approvalStatus !== "approved")
		return null;
	let myPaid = 0;
	for (const payer of input.payers) {
		if (payer.memberId === input.viewerMemberId) myPaid += payer.amount;
	}
	let myShare = 0;
	for (const share of input.shares) {
		if (share.memberId === input.viewerMemberId) myShare += share.amount;
	}
	if (myPaid === 0 && myShare === 0) return null;
	return input.type === "income" ? myShare - myPaid : myPaid - myShare;
}
export async function previewTransaction(
	deps: AppDeps,
	groupId: string,
	userId: string,
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
			const [group, owner] = await Promise.all([
				findGroup(executor, groupId),
				findGroupOwner(executor, groupId),
			]);
			const actorIsOwner = owner !== null && owner.userId === userId;
			const threshold = group?.approvalThreshold ?? null;
			const prospectiveStatus = replacing
				? nextEditApprovalStatusFor({
						type: replacing.type,
						amount: request.amount,
						threshold,
						actorIsOwner,
					})
				: approvalStatusFor({
						type: request.type,
						amount: request.amount,
						threshold,
						actorIsOwner,
					});
			const counted = prospectiveStatus !== "pending";
			const [shares, warnings] = await Promise.all([
				calculateShares(executor, groupId, request),
				transactionWarnings(executor, {
					groupId,
					request,
					applied: false,
					now: deps.now(),
					counted,
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

type TransactionRow = Awaited<ReturnType<typeof listTransactionRows>>[number];
type OpenDispute =
	Awaited<ReturnType<typeof listOpenDisputesForTransactions>> extends Map<
		string,
		infer D
	>
		? D
		: never;

function toCommonTransactionFields(input: {
	row: TransactionRow;
	commentCount: number;
	dispute: OpenDispute | undefined;
	viewerUserId: string | null;
	viewerMemberId: string | null;
	payers: Awaited<ReturnType<typeof listTransactionPayers>>;
	shares: Awaited<ReturnType<typeof listTransactionShares>>;
}) {
	const { row, dispute } = input;
	return {
		...row,
		occurredAt: row.occurredAt.toISOString(),
		createdAt: row.createdAt.toISOString(),
		updatedAt: row.updatedAt.toISOString(),
		deletedAt: row.deletedAt?.toISOString() ?? null,
		commentCount: input.commentCount,
		dispute: dispute
			? {
					id: dispute.id,
					reason: dispute.reason,
					openedByName: dispute.openedByName,
					openedAt: dispute.openedAt.toISOString(),
					mine:
						input.viewerUserId !== null &&
						dispute.openedBy === input.viewerUserId,
				}
			: null,
		approval: toApprovalDto(row),
		myDelta: computeMyDelta({
			type: row.type,
			deletedAt: row.deletedAt,
			approvalStatus: row.approvalStatus,
			viewerMemberId: input.viewerMemberId,
			payers: input.payers,
			shares: input.shares,
		}),
		payers: input.payers,
		shares: input.shares,
	};
}

export async function mapTransactions(
	executor: DbExecutor,
	groupId: string,
	rows: TransactionRow[],
	viewerUserId: string | null = null,
) {
	const ids = rows.map((row) => row.id);
	const [payers, shares, attachmentRows, commentCounts, disputes, access] =
		await Promise.all([
			listTransactionPayers(executor, groupId, ids),
			listTransactionShares(executor, groupId, ids),
			listAttachmentsForTransactions(executor, groupId, ids),
			countCommentsForTransactions(executor, groupId, ids),
			listOpenDisputesForTransactions(executor, groupId, ids),
			viewerUserId === null || rows.length === 0
				? Promise.resolve(null)
				: findGroupAccess(executor, groupId, viewerUserId),
		]);
	const viewerMemberId = access?.memberId ?? null;
	return rows.map((row) =>
		TransactionDto.parse({
			...toCommonTransactionFields({
				row,
				commentCount: commentCounts.get(row.id) ?? 0,
				dispute: disputes.get(row.id),
				viewerUserId,
				viewerMemberId,
				payers: payers.filter((payer) => payer.transactionId === row.id),
				shares: shares.filter((share) => share.transactionId === row.id),
			}),
			attachments: attachmentRows
				.filter((attachment) => attachment.transactionId === row.id)
				.map(toAttachmentDto),
		}),
	);
}

async function mapTransactionListItems(
	executor: DbExecutor,
	groupId: string,
	rows: TransactionRow[],
	viewerUserId: string | null = null,
) {
	const ids = rows.map((row) => row.id);
	const [payers, shares, attachmentSummaries, commentCounts, disputes, access] =
		await Promise.all([
			listTransactionPayers(executor, groupId, ids),
			listTransactionShares(executor, groupId, ids),
			listAttachmentSummariesForTransactions(executor, groupId, ids),
			countCommentsForTransactions(executor, groupId, ids),
			listOpenDisputesForTransactions(executor, groupId, ids),
			viewerUserId === null || rows.length === 0
				? Promise.resolve(null)
				: findGroupAccess(executor, groupId, viewerUserId),
		]);
	const viewerMemberId = access?.memberId ?? null;
	return rows.map((row) => {
		const attachmentSummary = attachmentSummaries.get(row.id);
		return TransactionListItemDto.parse({
			...toCommonTransactionFields({
				row,
				commentCount: commentCounts.get(row.id) ?? 0,
				dispute: disputes.get(row.id),
				viewerUserId,
				viewerMemberId,
				payers: payers.filter((payer) => payer.transactionId === row.id),
				shares: shares.filter((share) => share.transactionId === row.id),
			}),
			attachmentCount: attachmentSummary?.count ?? 0,
			firstAttachmentId: attachmentSummary?.firstAttachmentId ?? null,
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
		pushEnabled?: boolean;
	},
) {
	const group = await lockGroup(executor, input.groupId);
	await getGroupAccess(executor, { ...input, minimumRole: "editor" });
	assertGroupRowNotArchived(group);
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
		enqueue?: EnqueueFn;
		pushEnabled?: boolean;
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
			...(input.enqueue ? { enqueue: input.enqueue } : {}),
			...(input.pushEnabled === undefined
				? {}
				: { pushEnabled: input.pushEnabled }),
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
		pushEnabled?: boolean;
		allowedSettlementRequestId?: string;
	},
) {
	const shares = await calculateShares(executor, input.groupId, input.request);
	const request = normalizeTransaction(input.request);
	await assertLiveCategory(executor, input.groupId, request.categoryId ?? null);
	const attachmentIds = input.request.attachmentIds ?? [];
	await validateTransactionAttachmentIds(
		executor,
		input.groupId,
		attachmentIds,
		null,
		{
			transactionType: request.type,
			...(input.allowedSettlementRequestId
				? { allowedSettlementRequestId: input.allowedSettlementRequestId }
				: {}),
		},
	);
	const completedRecurringId =
		input.request.type === "expense"
			? input.request.recurringExpenseId
			: undefined;
	if (completedRecurringId !== undefined) {
		const existingRecurring = await findRecurringExpense(
			executor,
			input.groupId,
			completedRecurringId,
		);
		if (existingRecurring === null) {
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		}
	}
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
		paymentChannel: request.paymentChannel,
		paymentNote: request.paymentNote,
		recurringExpenseId: completedRecurringId ?? null,
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
	if (completedRecurringId !== undefined) {
		await updateRecurringExpense(
			executor,
			input.groupId,
			completedRecurringId,
			{
				pendingDueDate: null,
				amount: request.amount,
				lastPostedAt: input.now,
				lastTransactionId: row.id,
				updatedAt: input.now,
				updatedBy: input.userId,
			},
		);
	}
	if (
		input.request.type === "expense" &&
		input.request.recurring !== undefined
	) {
		const inline = input.request.recurring;
		const occurredDateVN = toVietnamDate(new Date(request.occurredAt));
		const occurredMs = new Date(request.occurredAt).getTime() + 7 * 3600_000;
		const occurredIsoDow = ((new Date(occurredMs).getUTCDay() + 6) % 7) + 1;
		const occurredDay = Number(occurredDateVN.slice(8, 10));
		const occurredMonth = Number(occurredDateVN.slice(5, 7));
		const createdRecurring = await createRecurringExpenseIn(executor, {
			groupId: input.groupId,
			userId: input.userId,
			request: {
				mode: inline.mode,
				description: request.description,
				amount: inline.mode === "fixed" ? request.amount : null,
				category: request.category,
				categoryId: request.categoryId,
				payersTemplate:
					inline.mode === "fixed"
						? request.payers
						: [{ memberId: request.payers[0]?.memberId ?? "" }],
				splitTemplate: request.split,
				frequency: inline.frequency,
				dayOfWeek:
					inline.frequency === "weekly"
						? (inline.dayOfWeek ?? occurredIsoDow)
						: null,
				dayOfMonth:
					inline.frequency === "weekly"
						? null
						: (inline.dayOfMonth ?? occurredDay),
				monthOfYear:
					inline.frequency === "yearly"
						? (inline.monthOfYear ?? occurredMonth)
						: null,
			},
			now: input.now,
			strictlyAfterToday: true,
			lastTransactionId: row.id,
		});
		await updateTransactionRow(executor, {
			groupId: input.groupId,
			id: row.id,
			changes: { recurringExpenseId: createdRecurring.recurringExpense.id },
		});
	}
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
				...(input.pushEnabled === undefined
					? {}
					: { pushEnabled: input.pushEnabled }),
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
			...(input.enqueue ? { enqueue: input.enqueue } : {}),
			...(input.pushEnabled === undefined
				? {}
				: { pushEnabled: input.pushEnabled }),
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
	const searchPattern = buildSearchPattern(query.q);
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
		...(query.cycleId === undefined ? {} : { cycleFilter: query.cycleId }),
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
			if (query.cycleId !== undefined && query.cycleId !== "current") {
				const cycle = await findSettlementCycle(
					executor,
					groupId,
					query.cycleId,
				);
				if (cycle === null) {
					throw new AppError(404, "NOT_FOUND", "Resource not found");
				}
			}
			const rows = await listTransactionRows(executor, {
				groupId,
				cursor: decodeTransactionCursor(query.cursor),
				limit: query.limit + 1,
				filters,
			});
			const page = rows.slice(0, query.limit);
			const last = page.at(-1);
			const nextCursor =
				rows.length > query.limit && last !== undefined
					? encodeTransactionCursor(last)
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
					...(request.extrasAllocation === undefined
						? {}
						: { extrasAllocation: request.extrasAllocation }),
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

function splitParticipantIds(split: SplitInput): string[] {
	if (split.method === "equal" || split.method === "exact") {
		return [...split.members];
	}
	if (split.method === "items") {
		return [...new Set(split.items.flatMap((item) => item.memberIds))];
	}
	return split.entries.map((entry) => entry.memberId);
}

function resolvePreviewPayers(
	request: PreviewExtrasRequest,
	computedAmount: number,
): Array<{ memberId: string; amount: number }> | null {
	if (request.payers !== undefined && request.payers.length > 0) {
		return request.payers.map((payer) => ({
			memberId: payer.memberId,
			amount: payer.amount ?? computedAmount,
		}));
	}
	if (request.payerMemberId !== undefined) {
		return [{ memberId: request.payerMemberId, amount: computedAmount }];
	}
	return null;
}

function resolvePreviewExtrasList(
	baseAmount: number,
	extras: PreviewExtrasRequest["extras"],
): { resolvedExtras: ItemsSplitExtra[]; netExtras: number } {
	const resolvedExtras: ItemsSplitExtra[] = extras.map((extra) =>
		extra.ratePercent !== undefined
			? {
					kind: extra.kind,
					label: extra.label,
					amount: computePercentExtraAmount(baseAmount, extra.ratePercent),
					ratePercent: extra.ratePercent,
				}
			: {
					kind: extra.kind,
					label: extra.label,
					amount: extra.amount ?? 0,
				},
	);
	let netExtras = 0;
	for (const extra of resolvedExtras) {
		netExtras += extra.kind === "discount" ? -extra.amount : extra.amount;
	}
	return { resolvedExtras, netExtras };
}

function validatePreviewMembers(
	members: Array<{ id: string; kind: string }>,
	payerIds: string[],
	splitIds: string[],
): void {
	const allIds = [...payerIds, ...splitIds];
	if (allIds.some((id) => !members.some((member) => member.id === id))) {
		throw new AppError(
			400,
			"MEMBER_NOT_IN_GROUP",
			"Member does not belong to group",
		);
	}
	if (
		splitIds.some(
			(id) => members.find((member) => member.id === id)?.kind === "fund",
		)
	) {
		throw new AppError(
			422,
			"FUND_CANNOT_SHARE",
			"Fund member cannot bear a share",
		);
	}
}

function computePreviewExtrasSplit(input: {
	baseAmount: number;
	computedAmount: number;
	request: PreviewExtrasRequest;
	resolvedExtras: ItemsSplitExtra[];
	memberIds: string[];
}): {
	shares?: Array<z.infer<typeof ShareDto>>;
	normalizedSplit?: SplitInput;
	issues: ExtrasPreviewIssue[];
} {
	const issues: ExtrasPreviewIssue[] = [];
	if (
		input.baseAmount < 1 ||
		input.computedAmount < 1 ||
		input.computedAmount > MAX_TRANSACTION_AMOUNT
	) {
		issues.push({ code: "INVALID_TOTAL" });
	}
	if (!input.request.split) return { issues };

	const allocation =
		input.request.extrasAllocation ?? input.request.split.extrasAllocation;
	const normalizedSplit: SplitInput = {
		...input.request.split,
		extras: input.resolvedExtras,
		...(allocation === undefined ? {} : { extrasAllocation: allocation }),
	};
	if (normalizedSplit.method === "items") {
		const unassignedIndex = normalizedSplit.items.findIndex(
			(item) => item.memberIds.length === 0,
		);
		if (unassignedIndex >= 0) {
			issues.push({ code: "ITEM_UNASSIGNED", itemIndex: unassignedIndex });
		}
	}
	if (
		input.baseAmount < 1 ||
		input.computedAmount < 1 ||
		input.computedAmount > MAX_TRANSACTION_AMOUNT
	) {
		return { normalizedSplit, issues };
	}

	const splitResult = computeShares(
		input.computedAmount,
		normalizedSplit,
		input.memberIds,
	);
	if (splitResult.ok) {
		return { shares: splitResult.shares, normalizedSplit, issues };
	}
	if (splitResult.code === "ITEM_UNASSIGNED") {
		if (!issues.some((issue) => issue.code === "ITEM_UNASSIGNED")) {
			issues.push({
				code: "ITEM_UNASSIGNED",
				itemIndex: splitResult.itemIndex,
			});
		}
		return { normalizedSplit, issues };
	}
	issues.push({ code: "SPLIT_TOTAL_MISMATCH" });
	return { normalizedSplit, issues };
}

async function computePreviewExtrasWarnings(
	executor: DbExecutor,
	input: {
		groupId: string;
		userId: string;
		computedAmount: number;
		request: PreviewExtrasRequest;
		normalizedSplit: SplitInput | undefined;
		members: Array<{ id: string }>;
		now: Date;
	},
): Promise<TransactionWarning[]> {
	const resolvedPayers = resolvePreviewPayers(
		input.request,
		input.computedAmount,
	);
	if (
		resolvedPayers === null ||
		resolvedPayers.reduce((sum, payer) => sum + payer.amount, 0) !==
			input.computedAmount
	) {
		return [];
	}

	let replacing: ReplacedTransaction | undefined;
	if (input.request.transactionId !== undefined) {
		const existing = await findTransactionRow(
			executor,
			input.groupId,
			input.request.transactionId,
		);
		if (existing === null || existing.deletedAt !== null) {
			throw new AppError(404, "NOT_FOUND", "Resource not found");
		}
		if (
			existing.type === "expense" ||
			existing.type === "income" ||
			existing.type === "transfer"
		) {
			const existingPayers = await listTransactionPayers(
				executor,
				input.groupId,
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
	}

	const [group, owner] = await Promise.all([
		findGroup(executor, input.groupId),
		findGroupOwner(executor, input.groupId),
	]);
	const actorIsOwner = owner !== null && owner.userId === input.userId;
	const threshold = group?.approvalThreshold ?? null;
	const prospectiveStatus = replacing
		? nextEditApprovalStatusFor({
				type: replacing.type,
				amount: input.computedAmount,
				threshold,
				actorIsOwner,
			})
		: approvalStatusFor({
				type: "expense",
				amount: input.computedAmount,
				threshold,
				actorIsOwner,
			});
	const fallbackSplit: SplitInput = input.normalizedSplit ?? {
		method: "equal",
		members: [resolvedPayers[0]?.memberId ?? input.members[0]?.id ?? ""],
	};
	return transactionWarnings(executor, {
		groupId: input.groupId,
		request: {
			type: "expense",
			description: "preview",
			amount: input.computedAmount,
			occurredAt: input.now.toISOString(),
			payers: resolvedPayers,
			split: fallbackSplit,
			category: null,
			categoryId: null,
		},
		applied: false,
		now: input.now,
		counted: prospectiveStatus !== "pending",
		...(replacing ? { replacing } : {}),
	});
}

export async function previewExtras(
	deps: AppDeps,
	groupId: string,
	userId: string,
	request: PreviewExtrasRequest,
): Promise<PreviewExtrasResponse> {
	return deps.db.transaction(
		async (executor) => {
			const members = await listGroupMembers(executor, groupId);
			const baseAmount =
				request.split?.method === "items"
					? request.split.items.reduce((sum, item) => sum + item.amount, 0)
					: request.baseAmount;
			const { resolvedExtras, netExtras } = resolvePreviewExtrasList(
				baseAmount,
				request.extras,
			);
			const computedAmount = baseAmount + netExtras;

			const splitIds = request.split ? splitParticipantIds(request.split) : [];
			const payerIds = [
				...(request.payers?.map((payer) => payer.memberId) ?? []),
				...(request.payerMemberId ? [request.payerMemberId] : []),
			];
			validatePreviewMembers(members, payerIds, splitIds);

			const { shares, normalizedSplit, issues } = computePreviewExtrasSplit({
				baseAmount,
				computedAmount,
				request,
				resolvedExtras,
				memberIds: members.map((member) => member.id),
			});

			const warnings =
				issues.length === 0 &&
				computedAmount >= 1 &&
				computedAmount <= MAX_TRANSACTION_AMOUNT
					? await computePreviewExtrasWarnings(executor, {
							groupId,
							userId,
							computedAmount,
							request,
							normalizedSplit,
							members,
							now: deps.now(),
						})
					: [];

			return PreviewExtrasResponse.parse({
				baseAmount,
				resolvedExtras,
				netExtras,
				computedAmount,
				...(shares === undefined ? {} : { shares }),
				issues,
				warnings,
			});
		},
		{ isolationLevel: "repeatable read", accessMode: "read only" },
	);
}
