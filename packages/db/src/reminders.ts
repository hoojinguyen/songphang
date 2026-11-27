import {
	type LedgerEntry,
	pairDebtsOf,
	suggestHouseholdSettlements,
} from "@songphang/core";
import { and, desc, eq, isNotNull } from "drizzle-orm";
import { listLedgerSides, listMemberBalances } from "./balances.js";
import type { DbExecutor } from "./client.js";
import { listGroupHouseholds } from "./households.js";
import { groups } from "./schema-groups.js";
import { debtReminders } from "./schema-reminders.js";

function ledgerDebts(sides: Awaited<ReturnType<typeof listLedgerSides>>) {
	return [...new Set(sides.payers.map((payer) => payer.transactionId))].flatMap(
		(id) => {
			const payers = sides.payers.filter((payer) => payer.transactionId === id);
			const type = payers[0]?.type;
			if (type !== "expense" && type !== "income" && type !== "transfer")
				throw new Error("Invalid ledger type");
			const entry: LedgerEntry = {
				type,
				payers,
				shares: sides.shares.filter((share) => share.transactionId === id),
			};
			return pairDebtsOf(entry);
		},
	);
}

export async function suggestGroupTransfers(
	executor: DbExecutor,
	input: { groupId: string; minimizeDebts: boolean },
) {
	const [balances, households] = await Promise.all([
		listMemberBalances(executor, input.groupId),
		listGroupHouseholds(executor, input.groupId),
	]);
	if (balances.length === 0) {
		return { balances: [], transfers: [], households: [] };
	}
	const { transfers, summaries } = suggestHouseholdSettlements({
		balancesByPosition: balances,
		minimizeDebts: input.minimizeDebts,
		...(input.minimizeDebts
			? {}
			: {
					pairDebts: ledgerDebts(
						await listLedgerSides(executor, input.groupId),
					),
				}),
		households,
	});
	return { balances, transfers, households: summaries };
}

export async function findLatestDebtReminder(
	executor: DbExecutor,
	input: { groupId: string; fromMemberId: string; toMemberId: string },
) {
	const [row] = await executor
		.select({
			id: debtReminders.id,
			createdAt: debtReminders.createdAt,
		})
		.from(debtReminders)
		.where(
			and(
				eq(debtReminders.groupId, input.groupId),
				eq(debtReminders.fromMemberId, input.fromMemberId),
				eq(debtReminders.toMemberId, input.toMemberId),
			),
		)
		.orderBy(desc(debtReminders.createdAt))
		.limit(1);
	return row ?? null;
}

export async function insertDebtReminder(
	executor: DbExecutor,
	input: {
		groupId: string;
		fromMemberId: string;
		toMemberId: string;
		amount: number;
		sentBy: string | null;
		createdAt: Date;
	},
) {
	const [row] = await executor
		.insert(debtReminders)
		.values(input)
		.returning({ id: debtReminders.id });
	if (!row) throw new Error("Debt reminder insert failed");
	return row;
}

export function listGroupsWithReminderInterval(executor: DbExecutor) {
	return executor
		.select({
			id: groups.id,
			name: groups.name,
			minimizeDebts: groups.minimizeDebts,
			reminderIntervalDays: groups.reminderIntervalDays,
		})
		.from(groups)
		.where(isNotNull(groups.reminderIntervalDays));
}
