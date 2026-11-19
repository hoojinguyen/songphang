import { and, eq, inArray, isNull } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { transactionDisputes } from "./schema-disputes.js";

export type DisputeRow = typeof transactionDisputes.$inferSelect;

export async function findOpenDisputeForTransaction(
	executor: DbExecutor,
	groupId: string,
	transactionId: string,
): Promise<DisputeRow | null> {
	const [row] = await executor
		.select()
		.from(transactionDisputes)
		.where(
			and(
				eq(transactionDisputes.groupId, groupId),
				eq(transactionDisputes.transactionId, transactionId),
				isNull(transactionDisputes.resolvedAt),
			),
		)
		.limit(1);
	return row ?? null;
}

export async function listOpenDisputesForTransactions(
	executor: DbExecutor,
	groupId: string,
	transactionIds: string[],
): Promise<Map<string, DisputeRow>> {
	if (transactionIds.length === 0) return new Map();
	const rows = await executor
		.select()
		.from(transactionDisputes)
		.where(
			and(
				eq(transactionDisputes.groupId, groupId),
				inArray(transactionDisputes.transactionId, transactionIds),
				isNull(transactionDisputes.resolvedAt),
			),
		);
	return new Map(rows.map((row) => [row.transactionId, row]));
}

export async function insertDisputeRow(
	executor: DbExecutor,
	input: {
		groupId: string;
		transactionId: string;
		reason: string;
		openedBy: string;
		openedByName: string;
		openedAt: Date;
	},
): Promise<DisputeRow> {
	const [row] = await executor
		.insert(transactionDisputes)
		.values(input)
		.returning();
	if (!row) throw new Error("Failed to insert dispute");
	return row;
}

export async function resolveDisputeRow(
	executor: DbExecutor,
	input: {
		groupId: string;
		disputeId: string;
		resolvedBy: string;
		resolvedAt: Date;
	},
): Promise<DisputeRow | null> {
	const [row] = await executor
		.update(transactionDisputes)
		.set({
			resolvedBy: input.resolvedBy,
			resolvedAt: input.resolvedAt,
		})
		.where(
			and(
				eq(transactionDisputes.groupId, input.groupId),
				eq(transactionDisputes.id, input.disputeId),
				isNull(transactionDisputes.resolvedAt),
			),
		)
		.returning();
	return row ?? null;
}
