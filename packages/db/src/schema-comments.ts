import { sql } from "drizzle-orm";
import {
	check,
	index,
	pgTable,
	text,
	timestamp,
	uuid,
} from "drizzle-orm/pg-core";
import { uuidv7 } from "uuidv7";
import { users } from "./schema.js";
import { groups } from "./schema-groups.js";
import { transactions } from "./schema-transactions.js";

export const comments = pgTable(
	"comments",
	{
		id: uuid("id").primaryKey().$defaultFn(uuidv7),
		groupId: uuid("group_id")
			.notNull()
			.references(() => groups.id, { onDelete: "cascade" }),
		transactionId: uuid("transaction_id")
			.notNull()
			.references(() => transactions.id, { onDelete: "cascade" }),
		authorUserId: uuid("author_user_id").references(() => users.id, {
			onDelete: "set null",
		}),
		authorName: text("author_name").notNull(),
		body: text("body").notNull(),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
		deletedAt: timestamp("deleted_at", { withTimezone: true }),
	},
	(table) => [
		check(
			"comments_author_name_check",
			sql`char_length(${table.authorName}) between 1 and 50`,
		),
		check(
			"comments_body_check",
			sql`char_length(${table.body}) between 1 and 1000`,
		),
		index("comments_transaction_created_index").on(
			table.transactionId,
			table.createdAt,
		),
	],
);
