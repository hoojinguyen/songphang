import { sql } from "drizzle-orm";
import {
	boolean,
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

export const aiCalls = pgTable(
	"ai_calls",
	{
		id: uuid("id").primaryKey().$defaultFn(uuidv7),
		userId: uuid("user_id").references(() => users.id, {
			onDelete: "set null",
		}),
		groupId: uuid("group_id").references(() => groups.id, {
			onDelete: "set null",
		}),
		purpose: text("purpose").notNull(),
		state: text("state").notNull().default("reserved"),
		model: text("model").notNull().default(""),
		inputTokens: integer("input_tokens").notNull().default(0),
		outputTokens: integer("output_tokens").notNull().default(0),
		ok: boolean("ok").notNull().default(false),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
		startedAt: timestamp("started_at", { withTimezone: true }),
		finishedAt: timestamp("finished_at", { withTimezone: true }),
	},
	(table) => [
		check(
			"ai_calls_purpose_check",
			sql`${table.purpose} in ('receipt', 'sentence')`,
		),
		check(
			"ai_calls_state_check",
			sql`${table.state} in ('reserved', 'started', 'finished')`,
		),
		check("ai_calls_input_tokens_check", sql`${table.inputTokens} >= 0`),
		check("ai_calls_output_tokens_check", sql`${table.outputTokens} >= 0`),
		index("ai_calls_purpose_created_index").on(table.purpose, table.createdAt),
		index("ai_calls_user_purpose_created_index").on(
			table.userId,
			table.purpose,
			table.createdAt,
		),
		index("ai_calls_created_index").on(table.createdAt),
	],
);
