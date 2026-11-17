import { sql } from "drizzle-orm";
import {
	bigint,
	check,
	pgTable,
	text,
	timestamp,
	uniqueIndex,
	uuid,
} from "drizzle-orm/pg-core";
import { uuidv7 } from "uuidv7";
import { users } from "./schema.js";
import { groups, members } from "./schema-groups.js";
import { transactions } from "./schema-transactions.js";
export const settlementRequests = pgTable(
	"settlement_requests",
	{
		id: uuid("id").primaryKey().$defaultFn(uuidv7),
		groupId: uuid("group_id")
			.notNull()
			.references(() => groups.id, { onDelete: "cascade" }),
		fromMemberId: uuid("from_member_id")
			.notNull()
			.references(() => members.id, { onDelete: "restrict" }),
		toMemberId: uuid("to_member_id")
			.notNull()
			.references(() => members.id, { onDelete: "restrict" }),
		amount: bigint("amount", { mode: "number" }).notNull(),
		status: text("status").notNull().default("pending"),
		transactionId: uuid("transaction_id").references(() => transactions.id, {
			onDelete: "set null",
		}),
		createdBy: uuid("created_by").references(() => users.id, {
			onDelete: "set null",
		}),
		resolvedBy: uuid("resolved_by").references(() => users.id, {
			onDelete: "set null",
		}),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
		resolvedAt: timestamp("resolved_at", { withTimezone: true }),
	},
	(table) => [
		check(
			"settlement_amount_check",
			sql`${table.amount} between 1 and 999999999999`,
		),
		check(
			"settlement_members_check",
			sql`${table.fromMemberId} <> ${table.toMemberId}`,
		),
		check(
			"settlement_status_check",
			sql`${table.status} in ('pending','confirmed','rejected','cancelled')`,
		),
		uniqueIndex("settlement_pending_pair_unique")
			.on(table.groupId, table.fromMemberId, table.toMemberId)
			.where(sql`${table.status} = 'pending'`),
	],
);
