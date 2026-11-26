import { sql } from "drizzle-orm";
import {
	type AnyPgColumn,
	bigint,
	boolean,
	check,
	date,
	index,
	integer,
	jsonb,
	pgTable,
	text,
	timestamp,
	uuid,
} from "drizzle-orm/pg-core";
import { uuidv7 } from "uuidv7";
import { users } from "./schema.js";
import { groupCategories } from "./schema-categories.js";
import { groups } from "./schema-groups.js";
import { transactions } from "./schema-transactions.js";

export const recurringExpenses = pgTable(
	"recurring_expenses",
	{
		id: uuid("id").primaryKey().$defaultFn(uuidv7),
		groupId: uuid("group_id")
			.notNull()
			.references(() => groups.id, { onDelete: "cascade" }),
		mode: text("mode").notNull(),
		active: boolean("active").notNull().default(true),
		description: text("description").notNull(),
		amount: bigint("amount", { mode: "number" }),
		category: text("category"),
		categoryId: uuid("category_id").references(() => groupCategories.id, {
			onDelete: "set null",
		}),
		payersTemplate: jsonb("payers_template").$type<unknown>().notNull(),
		splitTemplate: jsonb("split_template").$type<unknown>().notNull(),
		frequency: text("frequency").notNull(),
		dayOfWeek: integer("day_of_week"),
		dayOfMonth: integer("day_of_month"),
		monthOfYear: integer("month_of_year"),
		nextDueDate: date("next_due_date", { mode: "string" }).notNull(),
		pendingDueDate: date("pending_due_date", { mode: "string" }),
		lastProcessedDueDate: date("last_processed_due_date", { mode: "string" }),
		lastPostedAt: timestamp("last_posted_at", { withTimezone: true }),
		lastTransactionId: uuid("last_transaction_id").references(
			(): AnyPgColumn => transactions.id,
			{ onDelete: "set null" },
		),
		pauseReason: text("pause_reason"),
		createdBy: uuid("created_by").references(() => users.id, {
			onDelete: "set null",
		}),
		updatedBy: uuid("updated_by").references(() => users.id, {
			onDelete: "set null",
		}),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
		updatedAt: timestamp("updated_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
	},
	(table) => [
		index("recurring_expenses_group_idx").on(
			table.groupId,
			table.createdAt.desc(),
		),
		index("recurring_expenses_due_idx")
			.on(table.nextDueDate)
			.where(sql`${table.active} = true`),
		index("recurring_expenses_pending_idx")
			.on(table.groupId, table.pendingDueDate)
			.where(sql`${table.pendingDueDate} is not null`),
		check(
			"recurring_expenses_mode_check",
			sql`${table.mode} in ('fixed', 'variable')`,
		),
		check(
			"recurring_expenses_description_check",
			sql`char_length(${table.description}) between 1 and 200`,
		),
		check(
			"recurring_expenses_amount_check",
			sql`(${table.mode} = 'fixed' and ${table.amount} is not null and ${table.amount} > 0) or (${table.mode} = 'variable' and (${table.amount} is null or ${table.amount} > 0))`,
		),
		check(
			"recurring_expenses_category_check",
			sql`${table.category} is null or ${table.category} in ('food', 'transport', 'lodging', 'shopping', 'entertainment', 'bills', 'other')`,
		),
		check(
			"recurring_expenses_category_exclusive_check",
			sql`${table.category} is null or ${table.categoryId} is null`,
		),
		check(
			"recurring_expenses_frequency_check",
			sql`${table.frequency} in ('weekly', 'monthly', 'quarterly', 'yearly')`,
		),
		check(
			"recurring_expenses_day_of_week_check",
			sql`${table.dayOfWeek} is null or ${table.dayOfWeek} between 1 and 7`,
		),
		check(
			"recurring_expenses_day_of_month_check",
			sql`${table.dayOfMonth} is null or ${table.dayOfMonth} between 1 and 31`,
		),
		check(
			"recurring_expenses_month_of_year_check",
			sql`${table.monthOfYear} is null or ${table.monthOfYear} between 1 and 12`,
		),
		check(
			"recurring_expenses_pause_reason_check",
			sql`${table.pauseReason} is null or ${table.pauseReason} in ('member_invalid', 'split_invalid')`,
		),
		check(
			"recurring_expenses_schedule_fields_check",
			sql`(${table.frequency} = 'weekly' and ${table.dayOfWeek} is not null and ${table.dayOfMonth} is null and ${table.monthOfYear} is null) or (${table.frequency} in ('monthly', 'quarterly') and ${table.dayOfMonth} is not null and ${table.dayOfWeek} is null and ${table.monthOfYear} is null) or (${table.frequency} = 'yearly' and ${table.dayOfMonth} is not null and ${table.monthOfYear} is not null and ${table.dayOfWeek} is null)`,
		),
		check(
			"recurring_expenses_pending_mode_check",
			sql`${table.mode} = 'variable' or ${table.pendingDueDate} is null`,
		),
	],
);
