import { sql } from "drizzle-orm";
import { z } from "zod";
import type { DbExecutor } from "./client.js";
import { countedTransaction } from "./transactions.js";

const DateBoundsSchema = z.object({
	firstDate: z.string().nullable(),
	lastDate: z.string().nullable(),
});

const CategoryRowSchema = z.object({
	category: z.string().nullable(),
	categoryId: z.string().nullable(),
	amount: z.string(),
});

const MemberRowSchema = z.object({
	memberId: z.string(),
	paid: z.string(),
	share: z.string(),
});

const BucketRowSchema = z.object({
	start: z.string(),
	amount: z.string(),
	total: z.string(),
});

function dateFilter(range: { start?: Date; endExclusive?: Date }) {
	const startFilter =
		range.start === undefined
			? sql``
			: sql`and t.occurred_at >= to_timestamp(${range.start.getTime() / 1000})`;
	const endFilter =
		range.endExclusive === undefined
			? sql``
			: sql`and t.occurred_at < to_timestamp(${range.endExclusive.getTime() / 1000})`;
	return sql`${startFilter} ${endFilter}`;
}

export async function findCountedDateBounds(
	executor: DbExecutor,
	groupId: string,
	timeZone: string,
) {
	const rows = await executor.execute(sql`
		select
			to_char(min((t.occurred_at at time zone ${timeZone})::date), 'YYYY-MM-DD') as "firstDate",
			to_char(max((t.occurred_at at time zone ${timeZone})::date), 'YYYY-MM-DD') as "lastDate"
		from transactions t
		where t.group_id = ${groupId}
			and ${countedTransaction("t")}
			and t.type in ('expense', 'income')
	`);
	return DateBoundsSchema.parse(rows[0] ?? { firstDate: null, lastDate: null });
}

export async function sumByCategory(
	executor: DbExecutor,
	groupId: string,
	range: { start?: Date; endExclusive?: Date },
) {
	const filter = dateFilter(range);
	const rows = await executor.execute(sql`
		select
			t.category as category,
			t.category_id as "categoryId",
			coalesce(sum(case when t.type = 'income' then -t.amount else t.amount end), 0)::bigint::text as amount
		from transactions t
		where t.group_id = ${groupId}
			and ${countedTransaction("t")}
			and t.type in ('expense', 'income')
			${filter}
		group by t.category, t.category_id
		order by coalesce(sum(case when t.type = 'income' then -t.amount else t.amount end), 0) desc, t.category asc nulls last, t.category_id asc nulls last
	`);
	return z
		.array(CategoryRowSchema)
		.parse(rows)
		.map((row) => ({
			category: row.category,
			categoryId: row.categoryId,
			amount: Number(row.amount),
		}));
}

export async function sumByMember(
	executor: DbExecutor,
	groupId: string,
	range: { start?: Date; endExclusive?: Date },
) {
	const filter = dateFilter(range);
	const rows = await executor.execute(sql`
		with counted as (
			select t.id, t.type
			from transactions t
			where t.group_id = ${groupId}
				and ${countedTransaction("t")}
				and t.type in ('expense', 'income')
				${filter}
		),
		paid as (
			select tp.member_id, sum(case when c.type = 'income' then -tp.amount else tp.amount end)::bigint as total
			from transaction_payers tp
			join counted c on c.id = tp.transaction_id
			group by tp.member_id
		),
		shared as (
			select ts.member_id, sum(case when c.type = 'income' then -ts.amount else ts.amount end)::bigint as total
			from transaction_shares ts
			join counted c on c.id = ts.transaction_id
			group by ts.member_id
		)
		select
			m.id as "memberId",
			coalesce(p.total, 0)::text as paid,
			coalesce(s.total, 0)::text as share
		from members m
		left join paid p on p.member_id = m.id
		left join shared s on s.member_id = m.id
		where m.group_id = ${groupId}
		order by m.position asc
	`);
	return z
		.array(MemberRowSchema)
		.parse(rows)
		.map((row) => ({
			memberId: row.memberId,
			paid: Number(row.paid),
			share: Number(row.share),
		}));
}

export async function sumByBucket(
	executor: DbExecutor,
	input: {
		groupId: string;
		bucket: "day" | "week" | "month";
		timeZone: string;
		start?: Date;
		endExclusive?: Date;
	},
) {
	const filter = dateFilter(input);
	const rows = await executor.execute(sql`
		with bucketed as (
			select
				to_char(date_trunc(${input.bucket}, t.occurred_at at time zone ${input.timeZone}), 'YYYY-MM-DD') as start,
				sum(case when t.type = 'income' then -t.amount else t.amount end)::bigint as amount
			from transactions t
			where t.group_id = ${input.groupId}
				and ${countedTransaction("t")}
				and t.type in ('expense', 'income')
				${filter}
			group by 1
		)
		select
			start,
			amount::text as amount,
			(select coalesce(sum(amount), 0)::bigint::text from bucketed) as total
		from bucketed
		order by start asc
	`);
	const parsed = z.array(BucketRowSchema).parse(rows);
	return {
		total: parsed[0] ? Number(parsed[0].total) : 0,
		byBucket: parsed.map((row) => ({
			start: row.start,
			amount: Number(row.amount),
		})),
	};
}
