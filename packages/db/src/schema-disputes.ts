import { sql } from "drizzle-orm";
import {
	check,
	pgTable,
	text,
	timestamp,
	uniqueIndex,
	uuid,
} from "drizzle-orm/pg-core";
import { uuidv7 } from "uuidv7";
import { users } from "./schema.js";
import { groups } from "./schema-groups.js";
import { transactions } from "./schema-transactions.js";

export const transactionDisputes = pgTable(
	"transaction_disputes",
	{
		id: uuid("id").primaryKey().$defaultFn(uuidv7),
		groupId: uuid("group_id")
			.notNull()
			.references(() => groups.id, { onDelete: "cascade" }),
		transactionId: uuid("transaction_id")
			.notNull()
			.references(() => transactions.id, { onDelete: "cascade" }),
		reason: text("reason").notNull(),
		openedBy: uuid("opened_by").references(() => users.id, {
			onDelete: "set null",
		}),
		openedByName: text("opened_by_name").notNull(),
		openedAt: timestamp("opened_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
		resolvedBy: uuid("resolved_by").references(() => users.id, {
			onDelete: "set null",
		}),
		resolvedAt: timestamp("resolved_at", { withTimezone: true }),
	},
	(table) => [
		check(
			"transaction_disputes_reason_check",
			sql`char_length(${table.reason}) between 1 and 500`,
		),
		check(
			"transaction_disputes_opened_by_name_check",
			sql`char_length(${table.openedByName}) between 1 and 50`,
		),
		uniqueIndex("transaction_disputes_open_unique")
			.on(table.transactionId)
			.where(sql`${table.resolvedAt} is null`),
	],
);
