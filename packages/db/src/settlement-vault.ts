import { and, eq, inArray, isNull, sql } from "drizzle-orm";
import { alias } from "drizzle-orm/pg-core";
import { z } from "zod";
import type { DbExecutor } from "./client.js";
import { users } from "./schema.js";
import { attachments } from "./schema-attachments.js";
import { settlementRequests } from "./schema-settlements.js";
import { transactions } from "./schema-transactions.js";

export type VaultCursor = {
	isPending: boolean;
	sortAt: string;
	kind: "transfer" | "request";
	id: string;
};

const VAULT_PAGE_ROW = z.object({
	isPending: z.boolean(),
	sortAt: z.coerce.date(),
	kind: z.enum(["transfer", "request"]),
	id: z.uuid(),
});

const VAULT_SUMMARY_ROW = z.object({
	pendingCount: z.coerce.number().int().nonnegative(),
	confirmedCount: z.coerce.number().int().nonnegative(),
	confirmedTotalAmount: z.coerce.number().int().nonnegative(),
	proofCount: z.coerce.number().int().nonnegative(),
});

function transferCycleCondition(
	cycleFilter:
		| { kind: "all" }
		| { kind: "current" }
		| { kind: "cycle"; id: string },
) {
	if (cycleFilter.kind === "current") return sql`and t.cycle_id is null`;
	if (cycleFilter.kind === "cycle")
		return sql`and t.cycle_id = ${cycleFilter.id}::uuid`;
	return sql``;
}

function requestCycleCondition(
	cycleFilter:
		| { kind: "all" }
		| { kind: "current"; afterClosedAt: Date | null }
		| { kind: "cycle"; startedAt: Date; closedAt: Date },
) {
	if (cycleFilter.kind === "current") {
		return cycleFilter.afterClosedAt === null
			? sql``
			: sql`and (sr.status = 'pending' or sr.created_at >= ${cycleFilter.afterClosedAt.toISOString()}::timestamptz)`;
	}
	if (cycleFilter.kind === "cycle") {
		return sql`and sr.status <> 'pending' and sr.created_at >= ${cycleFilter.startedAt.toISOString()}::timestamptz and sr.created_at <= ${cycleFilter.closedAt.toISOString()}::timestamptz`;
	}
	return sql``;
}

export async function querySettlementVaultSummary(
	executor: DbExecutor,
	input: {
		groupId: string;
		transferCycle:
			| { kind: "all" }
			| { kind: "current" }
			| { kind: "cycle"; id: string };
		requestCycle:
			| { kind: "all" }
			| { kind: "current"; afterClosedAt: Date | null }
			| { kind: "cycle"; startedAt: Date; closedAt: Date };
	},
) {
	const tCycle = transferCycleCondition(input.transferCycle);
	const rCycle = requestCycleCondition(input.requestCycle);
	const rows = await executor.execute(sql`
		select
			(
				select count(*)::int
				from settlement_requests sr
				where sr.group_id = ${input.groupId}::uuid
					and sr.status = 'pending'
					${rCycle}
			) as "pendingCount",
			(
				select count(*)::int
				from transactions t
				where t.group_id = ${input.groupId}::uuid
					and t.deleted_at is null
					and t.type = 'transfer'
					${tCycle}
			) as "confirmedCount",
			(
				select coalesce(sum(t.amount), 0)::bigint::text
				from transactions t
				where t.group_id = ${input.groupId}::uuid
					and t.deleted_at is null
					and t.type = 'transfer'
					${tCycle}
			) as "confirmedTotalAmount",
			(
				(
					select count(*)::int
					from transactions t
					where t.group_id = ${input.groupId}::uuid
						and t.deleted_at is null
						and t.type = 'transfer'
						and exists (select 1 from attachments a where a.transaction_id = t.id)
						${tCycle}
				)
				+
				(
					select count(*)::int
					from settlement_requests sr
					where sr.group_id = ${input.groupId}::uuid
						and sr.status in ('pending', 'rejected', 'cancelled')
						and sr.proof_attachment_id is not null
						${rCycle}
				)
			) as "proofCount"
	`);
	return VAULT_SUMMARY_ROW.parse(rows[0]);
}

export async function listSettlementVaultKeys(
	executor: DbExecutor,
	input: {
		groupId: string;
		filter: "all" | "pending" | "confirmed" | "with_proof";
		transferCycle:
			| { kind: "all" }
			| { kind: "current" }
			| { kind: "cycle"; id: string };
		requestCycle:
			| { kind: "all" }
			| { kind: "current"; afterClosedAt: Date | null }
			| { kind: "cycle"; startedAt: Date; closedAt: Date };
		cursor: VaultCursor | null;
		limit: number;
	},
) {
	const tCycle = transferCycleCondition(input.transferCycle);
	const rCycle = requestCycleCondition(input.requestCycle);
	const includeTransfers =
		input.filter === "all" ||
		input.filter === "confirmed" ||
		input.filter === "with_proof";
	const includeRequests =
		input.filter === "all" ||
		input.filter === "pending" ||
		input.filter === "with_proof";

	const transferProofFilter =
		input.filter === "with_proof"
			? sql`and exists (select 1 from attachments a where a.transaction_id = t.id)`
			: sql``;
	const requestStatusFilter =
		input.filter === "pending"
			? sql`sr.status = 'pending'`
			: sql`sr.status in ('pending', 'rejected', 'cancelled')`;
	const requestProofFilter =
		input.filter === "with_proof"
			? sql`and sr.proof_attachment_id is not null`
			: sql``;

	const transferBranch = sql`
		select
			false as "isPending",
			t.occurred_at as "sortAt",
			'transfer'::text as "kind",
			t.id as "id"
		from transactions t
		where t.group_id = ${input.groupId}::uuid
			and t.deleted_at is null
			and t.type = 'transfer'
			${tCycle}
			${transferProofFilter}
	`;
	const requestBranch = sql`
		select
			(sr.status = 'pending') as "isPending",
			coalesce(sr.resolved_at, sr.created_at) as "sortAt",
			'request'::text as "kind",
			sr.id as "id"
		from settlement_requests sr
		where sr.group_id = ${input.groupId}::uuid
			and ${requestStatusFilter}
			${rCycle}
			${requestProofFilter}
	`;

	const unionSql =
		includeTransfers && includeRequests
			? sql`${transferBranch} union all ${requestBranch}`
			: includeTransfers
				? transferBranch
				: requestBranch;

	const cursorFilter =
		input.cursor === null
			? sql``
			: sql`
				where (
					(entries."isPending" < ${input.cursor.isPending})
					or (entries."isPending" = ${input.cursor.isPending} and entries."sortAt" < ${input.cursor.sortAt}::timestamptz)
					or (entries."isPending" = ${input.cursor.isPending} and entries."sortAt" = ${input.cursor.sortAt}::timestamptz and entries."kind" > ${input.cursor.kind})
					or (entries."isPending" = ${input.cursor.isPending} and entries."sortAt" = ${input.cursor.sortAt}::timestamptz and entries."kind" = ${input.cursor.kind} and entries."id" < ${input.cursor.id}::uuid)
				)
			`;

	const rows = await executor.execute(sql`
		select entries."isPending", entries."sortAt", entries."kind", entries."id"
		from (${unionSql}) as entries
		${cursorFilter}
		order by entries."isPending" desc, entries."sortAt" desc, entries."kind" asc, entries."id" desc
		limit ${input.limit}
	`);

	return z.array(VAULT_PAGE_ROW).parse(rows);
}

const vaultCreator = alias(users, "vault_creator");
const vaultResolver = alias(users, "vault_resolver");

export async function listVaultTransfersByIds(
	executor: DbExecutor,
	groupId: string,
	ids: string[],
) {
	if (ids.length === 0) return [];
	return executor
		.select({
			id: transactions.id,
			amount: transactions.amount,
			description: transactions.description,
			paymentChannel: transactions.paymentChannel,
			paymentNote: transactions.paymentNote,
			occurredAt: transactions.occurredAt,
			cycleId: transactions.cycleId,
			createdById: vaultCreator.id,
			createdByName: vaultCreator.name,
			settlementRequestId: settlementRequests.id,
			requestChannel: settlementRequests.channel,
			requestNote: settlementRequests.note,
			resolvedAt: settlementRequests.resolvedAt,
			resolvedById: vaultResolver.id,
			resolvedByName: vaultResolver.name,
		})
		.from(transactions)
		.leftJoin(vaultCreator, eq(vaultCreator.id, transactions.createdBy))
		.leftJoin(
			settlementRequests,
			and(
				eq(settlementRequests.groupId, groupId),
				eq(settlementRequests.transactionId, transactions.id),
				eq(settlementRequests.status, "confirmed"),
			),
		)
		.leftJoin(
			vaultResolver,
			eq(vaultResolver.id, settlementRequests.resolvedBy),
		)
		.where(
			and(
				eq(transactions.groupId, groupId),
				inArray(transactions.id, ids),
				isNull(transactions.deletedAt),
			),
		);
}

export async function listVaultRequestsByIds(
	executor: DbExecutor,
	groupId: string,
	ids: string[],
) {
	if (ids.length === 0) return [];
	return executor
		.select({
			request: settlementRequests,
			creatorName: vaultCreator.name,
			resolverName: vaultResolver.name,
			proofAttachment: attachments,
		})
		.from(settlementRequests)
		.leftJoin(vaultCreator, eq(vaultCreator.id, settlementRequests.createdBy))
		.leftJoin(
			vaultResolver,
			eq(vaultResolver.id, settlementRequests.resolvedBy),
		)
		.leftJoin(
			attachments,
			eq(attachments.id, settlementRequests.proofAttachmentId),
		)
		.where(
			and(
				eq(settlementRequests.groupId, groupId),
				inArray(settlementRequests.id, ids),
			),
		);
}
