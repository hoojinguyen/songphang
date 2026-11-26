import { sql } from "drizzle-orm";
import {
	type AnyPgColumn,
	check,
	index,
	pgTable,
	text,
	timestamp,
	uniqueIndex,
	uuid,
} from "drizzle-orm/pg-core";
import { uuidv7 } from "uuidv7";
import { groups, members } from "./schema-groups.js";

export const households = pgTable(
	"households",
	{
		id: uuid("id").primaryKey().$defaultFn(uuidv7),
		groupId: uuid("group_id")
			.notNull()
			.references(() => groups.id, { onDelete: "cascade" }),
		name: text("name").notNull(),
		representativeMemberId: uuid("representative_member_id")
			.notNull()
			.references((): AnyPgColumn => members.id, { onDelete: "restrict" }),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
		updatedAt: timestamp("updated_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
	},
	(table) => [
		index("households_group_idx").on(table.groupId, table.createdAt),
		uniqueIndex("households_representative_unique").on(
			table.representativeMemberId,
		),
		check(
			"households_name_length_check",
			sql`char_length(${table.name}) between 1 and 50`,
		),
	],
);
