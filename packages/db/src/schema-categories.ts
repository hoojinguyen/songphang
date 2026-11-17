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
import { groups } from "./schema-groups.js";

export const groupCategories = pgTable(
	"group_categories",
	{
		id: uuid("id").primaryKey().$defaultFn(uuidv7),
		groupId: uuid("group_id")
			.notNull()
			.references(() => groups.id, { onDelete: "cascade" }),
		name: text("name").notNull(),
		nameKey: text("name_key").notNull(),
		color: text("color").notNull(),
		archivedAt: timestamp("archived_at", { withTimezone: true }),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
		updatedAt: timestamp("updated_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
	},
	(table) => [
		uniqueIndex("group_categories_live_name_unique")
			.on(table.groupId, table.nameKey)
			.where(sql`${table.archivedAt} is null`),
		check(
			"group_categories_name_length_check",
			sql`char_length(${table.name}) between 1 and 30`,
		),
		check(
			"group_categories_color_check",
			sql`${table.color} in ('mint', 'sky', 'coral', 'lilac')`,
		),
	],
);
