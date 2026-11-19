import {
	boolean,
	index,
	jsonb,
	pgTable,
	text,
	timestamp,
	uuid,
} from "drizzle-orm/pg-core";
import { uuidv7 } from "uuidv7";
import { users } from "./schema.js";
import { groups } from "./schema-groups.js";

export const notifications = pgTable(
	"notifications",
	{
		id: uuid("id").primaryKey().$defaultFn(uuidv7),
		userId: uuid("user_id")
			.notNull()
			.references(() => users.id, { onDelete: "cascade" }),
		groupId: uuid("group_id")
			.notNull()
			.references(() => groups.id, { onDelete: "cascade" }),
		kind: text("kind").notNull(),
		payload: jsonb("payload").$type<unknown>().notNull(),
		readAt: timestamp("read_at", { withTimezone: true }),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
	},
	(table) => [
		index("notifications_user_created_index").on(
			table.userId,
			table.createdAt.desc(),
			table.id.desc(),
		),
	],
);

export const notificationSettings = pgTable("notification_settings", {
	userId: uuid("user_id")
		.primaryKey()
		.references(() => users.id, { onDelete: "cascade" }),
	emailImmediate: boolean("email_immediate").notNull().default(true),
	emailDigest: boolean("email_digest").notNull().default(true),
	unsubscribeTokenHash: text("unsubscribe_token_hash").unique(),
});

export const notificationUnsubscribeTokens = pgTable(
	"notification_unsubscribe_tokens",
	{
		id: uuid("id").primaryKey().$defaultFn(uuidv7),
		userId: uuid("user_id")
			.notNull()
			.references(() => users.id, { onDelete: "cascade" }),
		tokenHash: text("token_hash").notNull().unique(),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
	},
	(table) => [
		index("notification_unsubscribe_tokens_user_idx").on(
			table.userId,
			table.createdAt.desc(),
		),
	],
);

export const jobCheckpoints = pgTable("job_checkpoints", {
	name: text("name").primaryKey(),
	lastRunAt: timestamp("last_run_at", { withTimezone: true }).notNull(),
});
