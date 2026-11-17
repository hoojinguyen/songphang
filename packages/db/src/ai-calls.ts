import { quotaWindowStarts } from "@songphang/core";
import { and, count, eq, gte, inArray, sql } from "drizzle-orm";
import type { DbExecutor } from "./client.js";
import { aiCalls } from "./schema-ai.js";

export type AiPurpose = "receipt" | "sentence";
export type AiCallRow = typeof aiCalls.$inferSelect;

const AI_QUOTA_LOCK_KEY = 93847102;

export async function countAiCalls(
	executor: DbExecutor,
	input: { purpose?: AiPurpose; userId?: string; since: Date },
): Promise<number> {
	const [row] = await executor
		.select({ total: count() })
		.from(aiCalls)
		.where(
			and(
				gte(aiCalls.createdAt, input.since),
				input.purpose === undefined
					? undefined
					: eq(aiCalls.purpose, input.purpose),
				input.userId === undefined
					? undefined
					: eq(aiCalls.userId, input.userId),
			),
		);
	return Number(row?.total ?? 0);
}

export async function reserveAiCall(
	executor: DbExecutor,
	input: {
		purpose: AiPurpose;
		userId: string;
		groupId: string;
		limits: { userDaily: number; monthTotal: number };
		now: Date;
	},
): Promise<
	| { status: "ok"; reservationId: string }
	| { status: "user_limit" | "month_limit" }
> {
	const { dayStart, monthStart } = quotaWindowStarts(input.now);
	return executor.transaction(async (tx) => {
		await tx.execute(sql`SELECT pg_advisory_xact_lock(${AI_QUOTA_LOCK_KEY})`);
		const monthCount = await countAiCalls(tx, { since: monthStart });
		if (monthCount >= input.limits.monthTotal) {
			return { status: "month_limit" as const };
		}
		const userCount = await countAiCalls(tx, {
			purpose: input.purpose,
			userId: input.userId,
			since: dayStart,
		});
		if (userCount >= input.limits.userDaily) {
			return { status: "user_limit" as const };
		}
		const [row] = await tx
			.insert(aiCalls)
			.values({
				userId: input.userId,
				groupId: input.groupId,
				purpose: input.purpose,
				state: "reserved",
				model: "",
				inputTokens: 0,
				outputTokens: 0,
				ok: false,
				createdAt: input.now,
			})
			.returning({ id: aiCalls.id });
		if (!row) throw new Error("Failed to reserve AI call");
		return { status: "ok" as const, reservationId: row.id };
	});
}

export async function findAiCall(
	executor: DbExecutor,
	id: string,
): Promise<AiCallRow | null> {
	const [row] = await executor
		.select()
		.from(aiCalls)
		.where(eq(aiCalls.id, id))
		.limit(1);
	return row ?? null;
}

export async function claimAiCall(
	executor: DbExecutor,
	input: {
		id: string;
		purpose: AiPurpose;
		userId: string;
		groupId: string;
		startedAt: Date;
	},
): Promise<AiCallRow | null> {
	const [row] = await executor
		.update(aiCalls)
		.set({
			state: "started",
			startedAt: input.startedAt,
		})
		.where(
			and(
				eq(aiCalls.id, input.id),
				eq(aiCalls.state, "reserved"),
				eq(aiCalls.purpose, input.purpose),
				eq(aiCalls.userId, input.userId),
				eq(aiCalls.groupId, input.groupId),
			),
		)
		.returning();
	return row ?? null;
}

export async function recordAiCall(
	executor: DbExecutor,
	input: {
		id?: string;
		userId?: string | null;
		groupId?: string | null;
		purpose?: AiPurpose;
		model: string;
		inputTokens: number;
		outputTokens: number;
		ok: boolean;
		finishedAt: Date;
	},
): Promise<void> {
	if (input.id !== undefined) {
		await executor
			.update(aiCalls)
			.set({
				state: "finished",
				model: input.model,
				inputTokens: input.inputTokens,
				outputTokens: input.outputTokens,
				ok: input.ok,
				finishedAt: input.finishedAt,
			})
			.where(
				and(
					eq(aiCalls.id, input.id),
					inArray(aiCalls.state, ["reserved", "started"]),
				),
			);
		return;
	}
	if (!input.purpose) {
		throw new Error("purpose is required when inserting an ai_calls row");
	}
	await executor.insert(aiCalls).values({
		userId: input.userId ?? null,
		groupId: input.groupId ?? null,
		purpose: input.purpose,
		state: "finished",
		model: input.model,
		inputTokens: input.inputTokens,
		outputTokens: input.outputTokens,
		ok: input.ok,
		createdAt: input.finishedAt,
		finishedAt: input.finishedAt,
	});
}
