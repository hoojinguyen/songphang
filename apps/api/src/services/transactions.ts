import { z } from "@hono/zod-openapi";
import {
	type CreateTransactionRequest,
	PreviewTransactionResponse,
	TransactionDto,
	TransactionResponse,
	type TransactionsQuery,
	TransactionsResponse,
} from "@songphang/contract";
import { foldVietnamese, localDateRangeToUtc } from "@songphang/core";
import {
	type DbExecutor,
	findGroup,
	findTransactionRow,
	insertActivity,
	insertTransaction,
	insertTransactionPayers,
	insertTransactionShares,
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
import { assertLiveCategory } from "./categories.js";
import { calculateShares, normalizeTransaction } from "./transaction-input.js";

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
	request: CreateTransactionRequest,
) {
	if (request.type !== "transfer")
		await assertLiveCategory(deps.db, groupId, request.categoryId);
	return PreviewTransactionResponse.parse({
		shares: await calculateShares(deps.db, groupId, request),
	});
}
export async function mapTransactions(
	executor: DbExecutor,
	groupId: string,
	rows: Awaited<ReturnType<typeof listTransactionRows>>,
) {
	const ids = rows.map((row) => row.id);
	const [payers, shares] = await Promise.all([
		listTransactionPayers(executor, groupId, ids),
		listTransactionShares(executor, groupId, ids),
	]);
	return rows.map((row) =>
		TransactionDto.parse({
			...row,
			occurredAt: row.occurredAt.toISOString(),
			createdAt: row.createdAt.toISOString(),
			updatedAt: row.updatedAt.toISOString(),
			deletedAt: row.deletedAt?.toISOString() ?? null,
			payers: payers.filter((payer) => payer.transactionId === row.id),
			shares: shares.filter((share) => share.transactionId === row.id),
		}),
	);
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
	const [transaction] = await mapTransactions(executor, input.groupId, [
		stored,
	]);
	return TransactionResponse.parse({ transaction });
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
				transactions: await mapTransactions(executor, groupId, page),
				nextCursor,
			});
		},
		{ isolationLevel: "repeatable read", accessMode: "read only" },
	);
}
