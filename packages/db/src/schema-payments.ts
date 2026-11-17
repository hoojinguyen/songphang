import { sql } from "drizzle-orm";
import {
	check,
	pgTable,
	text,
	timestamp,
	unique,
	uuid,
} from "drizzle-orm/pg-core";
import { uuidv7 } from "uuidv7";
import { members } from "./schema-groups.js";
export const memberPaymentMethods = pgTable(
	"member_payment_methods",
	{
		id: uuid("id").primaryKey().$defaultFn(uuidv7),
		memberId: uuid("member_id")
			.notNull()
			.references(() => members.id, { onDelete: "cascade" }),
		kind: text("kind").notNull(),
		bankBin: text("bank_bin"),
		accountNumber: text("account_number").notNull(),
		accountName: text("account_name"),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
		updatedAt: timestamp("updated_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
	},
	(table) => [
		unique("member_payment_methods_kind_unique").on(table.memberId, table.kind),
		check(
			"payment_kind_check",
			sql`${table.kind} in ('bank','momo','zalopay')`,
		),
		check(
			"payment_bank_check",
			sql`(${table.kind} = 'bank' and ${table.bankBin} is not null and ${table.bankBin} ~ '^[0-9]{6}$' and ${table.accountName} is not null and char_length(${table.accountName}) between 1 and 50 and ${table.accountNumber} ~ '^[A-Za-z0-9]{4,19}$') or (${table.kind} <> 'bank' and ${table.bankBin} is null and ${table.accountNumber} ~ '^0[0-9]{9}$')`,
		),
	],
);
