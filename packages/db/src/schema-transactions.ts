import { sql } from "drizzle-orm";
import {
	bigint,
	check,
	index,
	integer,
	jsonb,
	pgTable,
	primaryKey,
	text,
	timestamp,
	uuid,
} from "drizzle-orm/pg-core";
import { uuidv7 } from "uuidv7";
import { users } from "./schema.js";
import { groupCategories } from "./schema-categories.js";
import { groups, members } from "./schema-groups.js";

export const transactions = pgTable(
	"transactions",
	{
		id: uuid("id").primaryKey().$defaultFn(uuidv7),
		groupId: uuid("group_id")
			.notNull()
			.references(() => groups.id, { onDelete: "cascade" }),
		type: text("type").notNull(),
		description: text("description").notNull(),
		amount: bigint("amount", { mode: "number" }).notNull(),
		currency: text("currency").notNull(),
		occurredAt: timestamp("occurred_at", { withTimezone: true }).notNull(),
		category: text("category"),
		categoryId: uuid("category_id").references(() => groupCategories.id, {
			onDelete: "set null",
		}),
		splitMethod: text("split_method").notNull(),
		splitInput: jsonb("split_input").$type<unknown>().notNull(),
		version: integer("version").notNull().default(1),
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
		deletedAt: timestamp("deleted_at", { withTimezone: true }),
	},
	(table) => [
		check(
			"transactions_type_check",
			sql`${table.type} in ('expense', 'transfer', 'income')`,
		),
		check(
			"transactions_description_check",
			sql`char_length(${table.description}) between 1 and 200`,
		),
		check(
			"transactions_amount_check",
			sql`${table.amount} between 1 and 999999999999`,
		),
		check(
			"transactions_category_check",
			sql`${table.category} is null or ${table.category} in ('food', 'transport', 'lodging', 'shopping', 'entertainment', 'bills', 'other')`,
		),
		check(
			"transactions_category_exclusive_check",
			sql`${table.category} is null or ${table.categoryId} is null`,
		),
		check(
			"transactions_split_method_check",
			sql`${table.splitMethod} in ('equal', 'exact', 'shares', 'percent')`,
		),
		index("transactions_group_feed_index")
			.on(table.groupId, table.occurredAt.desc(), table.id.desc())
			.where(sql`${table.deletedAt} is null`),
	],
);

export const transactionPayers = pgTable(
	"transaction_payers",
	{
		transactionId: uuid("transaction_id")
			.notNull()
			.references(() => transactions.id, { onDelete: "cascade" }),
		memberId: uuid("member_id")
			.notNull()
			.references(() => members.id, { onDelete: "restrict" }),
		amount: bigint("amount", { mode: "number" }).notNull(),
	},
	(table) => [
		primaryKey({ columns: [table.transactionId, table.memberId] }),
		check("transaction_payers_amount_check", sql`${table.amount} > 0`),
	],
);

export const transactionShares = pgTable(
	"transaction_shares",
	{
		transactionId: uuid("transaction_id")
			.notNull()
			.references(() => transactions.id, { onDelete: "cascade" }),
		memberId: uuid("member_id")
			.notNull()
			.references(() => members.id, { onDelete: "restrict" }),
		amount: bigint("amount", { mode: "number" }).notNull(),
	},
	(table) => [
		primaryKey({ columns: [table.transactionId, table.memberId] }),
		check("transaction_shares_amount_check", sql`${table.amount} >= 0`),
	],
);
