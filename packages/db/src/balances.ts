import { and, eq, sql } from "drizzle-orm";
import { z } from "zod";
import type { DbExecutor } from "./client.js";
import { members } from "./schema-groups.js";
import {
	transactionPayers,
	transactionShares,
	transactions,
} from "./schema-transactions.js";
import { countedTransaction } from "./transactions.js";

const BALANCE_ROW = z.object({
	memberId: z.uuid(),
	groupId: z.uuid(),
	balance: z.coerce.number().int().safe(),
});
export async function listBalancesForGroups(
	executor: DbExecutor,
	groupIds: string[],
) {
	if (groupIds.length === 0) return [];
	const rows = await executor.execute(sql`
 select m.id as "memberId", m.group_id as "groupId", coalesce(sum(x.signed),0)::bigint::text as balance
 from members m left join (
 select p.member_id, case when t.type = 'income' then -p.amount else p.amount end as signed
 from transaction_payers p join transactions t on t.id = p.transaction_id
 where t.group_id in (${sql.join(
		groupIds.map((id) => sql`${id}::uuid`),
		sql`, `,
 )}) and ${countedTransaction("t")}
 union all
 select s.member_id, case when t.type = 'income' then s.amount else -s.amount end
 from transaction_shares s join transactions t on t.id = s.transaction_id
 where t.group_id in (${sql.join(
		groupIds.map((id) => sql`${id}::uuid`),
		sql`, `,
 )}) and ${countedTransaction("t")}
 ) x on x.member_id = m.id
 where m.group_id in (${sql.join(
		groupIds.map((id) => sql`${id}::uuid`),
		sql`, `,
 )})
 group by m.id order by m.position
 `);
	return z.array(BALANCE_ROW).parse(rows);
}
export function listMemberBalances(executor: DbExecutor, groupId: string) {
	return listBalancesForGroups(executor, [groupId]);
}

export async function listLedgerSides(executor: DbExecutor, groupId: string) {
	const payers = await executor
		.select({
			transactionId: transactionPayers.transactionId,
			type: transactions.type,
			memberId: transactionPayers.memberId,
			amount: transactionPayers.amount,
		})
		.from(transactionPayers)
		.innerJoin(
			transactions,
			eq(transactions.id, transactionPayers.transactionId),
		)
		.innerJoin(members, eq(members.id, transactionPayers.memberId))
		.where(
			and(
				eq(transactions.groupId, groupId),
				countedTransaction("transactions"),
			),
		)
		.orderBy(members.position);
	const shares = await executor
		.select({
			transactionId: transactionShares.transactionId,
			memberId: transactionShares.memberId,
			amount: transactionShares.amount,
		})
		.from(transactionShares)
		.innerJoin(
			transactions,
			eq(transactions.id, transactionShares.transactionId),
		)
		.innerJoin(members, eq(members.id, transactionShares.memberId))
		.where(
			and(
				eq(transactions.groupId, groupId),
				countedTransaction("transactions"),
			),
		)
		.orderBy(members.position);
	return { payers, shares };
}
