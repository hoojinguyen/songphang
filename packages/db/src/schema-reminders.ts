import { sql } from "drizzle-orm";
import {
	bigint,
	check,
	index,
	pgTable,
	timestamp,
	uuid,
} from "drizzle-orm/pg-core";
import { uuidv7 } from "uuidv7";
import { users } from "./schema.js";
import { groups, members } from "./schema-groups.js";

export const debtReminders = pgTable(
	"debt_reminders",
	{
		id: uuid("id").primaryKey().$defaultFn(uuidv7),
		groupId: uuid("group_id")
			.notNull()
			.references(() => groups.id, { onDelete: "cascade" }),
		fromMemberId: uuid("from_member_id")
			.notNull()
			.references(() => members.id, { onDelete: "cascade" }),
		toMemberId: uuid("to_member_id")
			.notNull()
			.references(() => members.id, { onDelete: "cascade" }),
		amount: bigint("amount", { mode: "number" }).notNull(),
		sentBy: uuid("sent_by").references(() => users.id, {
			onDelete: "set null",
		}),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
	},
	(table) => [
		check("debt_reminders_amount_check", sql`${table.amount} > 0`),
		index("debt_reminders_pair_created_index").on(
			table.groupId,
			table.fromMemberId,
			table.toMemberId,
			table.createdAt.desc(),
		),
	],
);
