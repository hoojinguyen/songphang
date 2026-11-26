import { sql } from "drizzle-orm";
import {
	bigint,
	check,
	index,
	integer,
	jsonb,
	pgTable,
	text,
	timestamp,
	unique,
	uuid,
} from "drizzle-orm/pg-core";
import { uuidv7 } from "uuidv7";
import { users } from "./schema.js";
import { groups } from "./schema-groups.js";

export const settlementCycles = pgTable(
	"settlement_cycles",
	{
		id: uuid("id").primaryKey().$defaultFn(uuidv7),
		groupId: uuid("group_id")
			.notNull()
			.references(() => groups.id, { onDelete: "cascade" }),
		cycleNumber: integer("cycle_number").notNull(),
		title: text("title").notNull(),
		startedAt: timestamp("started_at", { withTimezone: true }).notNull(),
		closedAt: timestamp("closed_at", { withTimezone: true }).notNull(),
		closedBy: uuid("closed_by").references(() => users.id, {
			onDelete: "set null",
		}),
		expenseCount: integer("expense_count").notNull().default(0),
		totalExpenseAmount: bigint("total_expense_amount", { mode: "number" })
			.notNull()
			.default(0),
		snapshot: jsonb("snapshot").$type<unknown>().notNull(),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
	},
	(table) => [
		unique("settlement_cycles_group_cycle_unique").on(
			table.groupId,
			table.cycleNumber,
		),
		index("settlement_cycles_group_closed_idx").on(
			table.groupId,
			table.cycleNumber.desc(),
		),
		check("settlement_cycles_number_check", sql`${table.cycleNumber} >= 1`),
		check(
			"settlement_cycles_title_check",
			sql`char_length(${table.title}) between 1 and 80`,
		),
		check(
			"settlement_cycles_closed_at_check",
			sql`${table.closedAt} >= ${table.startedAt}`,
		),
		check(
			"settlement_cycles_expense_count_check",
			sql`${table.expenseCount} >= 0`,
		),
		check(
			"settlement_cycles_total_amount_check",
			sql`${table.totalExpenseAmount} >= 0`,
		),
	],
);
