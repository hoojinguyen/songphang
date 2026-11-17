import { sql } from "drizzle-orm";
import {
	bigint,
	check,
	pgTable,
	text,
	timestamp,
	uuid,
} from "drizzle-orm/pg-core";
import { users } from "./schema.js";
import { groups } from "./schema-groups.js";

export const budgets = pgTable(
	"budgets",
	{
		groupId: uuid("group_id")
			.primaryKey()
			.references(() => groups.id, { onDelete: "cascade" }),
		period: text("period").notNull(),
		amount: bigint("amount", { mode: "number" }).notNull(),
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
		check("budgets_period_check", sql`${table.period} in ('month', 'total')`),
		check("budgets_amount_positive_check", sql`${table.amount} > 0`),
	],
);
