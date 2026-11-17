import { fileURLToPath } from "node:url";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { createDb, type Db } from "./client.js";

const GROUP_BALANCE_SCHEMA = z.object({
	id: z.uuid(),
	name: z.string(),
	balance: z.string(),
	mismatches: z.string(),
});

export async function checkBalances(db: Db): Promise<boolean> {
	const totals = await db.execute(sql`
  select g.id, g.name, coalesce(sum(lines.signed), 0)::text as balance
  from groups g
  left join (
   select t.group_id, case when t.type = 'income' then -p.amount else p.amount end as signed
   from transaction_payers p join transactions t on t.id = p.transaction_id where t.deleted_at is null
   union all
   select t.group_id, case when t.type = 'income' then s.amount else -s.amount end
   from transaction_shares s join transactions t on t.id = s.transaction_id where t.deleted_at is null
  ) lines on lines.group_id = g.id group by g.id order by g.id
 `);
	const mismatches = await db.execute(sql`
  select g.id, count(t.id) filter (where
   (select coalesce(sum(p.amount), 0) from transaction_payers p where p.transaction_id = t.id) <> t.amount
   or (select coalesce(sum(s.amount), 0) from transaction_shares s where s.transaction_id = t.id) <> t.amount
   or exists (
    select 1 from transaction_shares s
    join members m on m.id = s.member_id
    where s.transaction_id = t.id and m.kind = 'fund' and t.type in ('expense', 'income')
   )
  )::text as mismatches
  from groups g left join transactions t on t.group_id = g.id and t.deleted_at is null group by g.id
 `);
	if (totals.length === 0) {
		console.log("No groups");
		return true;
	}
	const mismatchRows = z
		.array(z.object({ id: z.uuid(), mismatches: z.string() }))
		.parse(mismatches);
	let isBalanced = true;
	for (const total of totals) {
		const row = GROUP_BALANCE_SCHEMA.parse({
			...total,
			mismatches: mismatchRows.find((row) => row.id === total.id)?.mismatches,
		});
		console.log(
			`${row.id} ${row.name}: sum ${row.balance}; mismatches ${row.mismatches}`,
		);
		if (BigInt(row.balance) !== 0n || BigInt(row.mismatches) !== 0n)
			isBalanced = false;
	}
	console.log(isBalanced ? "All groups balanced" : "IMBALANCE FOUND");
	return isBalanced;
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
	try {
		const { db, close } = createDb(process.env.DATABASE_URL ?? "");
		try {
			if (!(await checkBalances(db))) process.exitCode = 1;
		} finally {
			await close();
		}
	} catch {
		console.error(
			"Balance check failed: check DATABASE_URL and database migrations",
		);
		process.exitCode = 1;
	}
}
