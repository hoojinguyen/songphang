import { sql } from "drizzle-orm";
import { z } from "zod";
import { listMemberBalances } from "./balances.js";
import type { DbExecutor } from "./client.js";
import { findFund } from "./members.js";

const ContributionRowSchema = z.object({
	memberId: z.uuid(),
	amount: z.coerce.number().int().safe(),
});

export async function fundCashAndContributions(
	executor: DbExecutor,
	groupId: string,
) {
	const fund = await findFund(executor, groupId);
	if (fund === null) return null;
	const balances = await listMemberBalances(executor, groupId);
	const fundBalance =
		balances.find((row) => row.memberId === fund.id)?.balance ?? 0;
	const rows = await executor.execute(sql`
		select
			m.id as "memberId",
			coalesce(sum(
				case
					when p.member_id = m.id and s.member_id = ${fund.id}::uuid then p.amount
					when p.member_id = ${fund.id}::uuid and s.member_id = m.id then -p.amount
					else 0
				end
			), 0)::bigint::text as amount
		from members m
		join transactions t on t.group_id = ${groupId}::uuid
			and t.type = 'transfer'
			and t.deleted_at is null
		join transaction_payers p on p.transaction_id = t.id
		join transaction_shares s on s.transaction_id = t.id
		where m.group_id = ${groupId}::uuid
			and m.kind = 'person'
			and (
				(p.member_id = m.id and s.member_id = ${fund.id}::uuid)
				or (p.member_id = ${fund.id}::uuid and s.member_id = m.id)
			)
		group by m.id, m.position
		having coalesce(sum(
			case
				when p.member_id = m.id and s.member_id = ${fund.id}::uuid then p.amount
				when p.member_id = ${fund.id}::uuid and s.member_id = m.id then -p.amount
				else 0
			end
		), 0) <> 0
		order by m.position asc
	`);
	return {
		memberId: fund.id,
		name: fund.name,
		active: fund.active,
		cash: -fundBalance,
		holderMemberId: fund.fundHolderMemberId,
		contributions: z.array(ContributionRowSchema).parse(rows),
	};
}
