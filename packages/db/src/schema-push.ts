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
import { sessions, users } from "./schema.js";

export const pushDevices = pgTable(
	"push_devices",
	{
		id: uuid("id").primaryKey().$defaultFn(uuidv7),
		userId: uuid("user_id")
			.notNull()
			.references(() => users.id, { onDelete: "cascade" }),
		sessionId: uuid("session_id")
			.notNull()
			.references(() => sessions.id, { onDelete: "cascade" }),
		platform: text("platform").notNull(),
		token: text("token").notNull().unique(),
		environment: text("environment").notNull(),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
		lastSeenAt: timestamp("last_seen_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
	},
	(table) => [
		index("push_devices_user_id_idx").on(table.userId),
		index("push_devices_session_id_idx").on(table.sessionId),
		check(
			"push_devices_platform_check",
			sql`${table.platform} in ('ios', 'android')`,
		),
		check(
			"push_devices_environment_check",
			sql`${table.environment} in ('sandbox', 'production')`,
		),
		check(
			"push_devices_token_length_check",
			sql`char_length(${table.token}) between 16 and 512`,
		),
	],
);
