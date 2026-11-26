import { sql } from "drizzle-orm";
import {
	check,
	index,
	integer,
	pgTable,
	text,
	timestamp,
	uuid,
} from "drizzle-orm/pg-core";
import { uuidv7 } from "uuidv7";
import { users } from "./schema.js";
import { groups } from "./schema-groups.js";
import { transactions } from "./schema-transactions.js";

export const attachments = pgTable(
	"attachments",
	{
		id: uuid("id").primaryKey().$defaultFn(uuidv7),
		groupId: uuid("group_id")
			.notNull()
			.references(() => groups.id, { onDelete: "cascade" }),
		transactionId: uuid("transaction_id").references(() => transactions.id, {
			onDelete: "cascade",
		}),
		storageKey: text("storage_key").notNull().unique(),
		contentType: text("content_type").notNull(),
		byteSize: integer("byte_size").notNull(),
		sha256: text("sha256").notNull(),
		purpose: text("purpose").notNull().default("expense"),
		uploadedBy: uuid("uploaded_by").references(() => users.id, {
			onDelete: "set null",
		}),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
	},
	(table) => [
		check(
			"attachments_content_type_check",
			sql`${table.contentType} in ('image/jpeg', 'image/png', 'image/webp')`,
		),
		check(
			"attachments_byte_size_check",
			sql`${table.byteSize} between 1 and 5242880`,
		),
		check(
			"attachments_purpose_check",
			sql`${table.purpose} in ('expense', 'transfer_proof')`,
		),
		index("attachments_group_index").on(table.groupId),
		index("attachments_transaction_index").on(table.transactionId),
	],
);
