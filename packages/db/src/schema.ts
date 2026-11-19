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

export const users = pgTable(
	"users",
	{
		id: uuid("id").primaryKey().$defaultFn(uuidv7),
		email: text("email").notNull(),
		emailVerifiedAt: timestamp("email_verified_at", { withTimezone: true }),
		name: text("name").notNull(),
		avatarUrl: text("avatar_url"),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
		updatedAt: timestamp("updated_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
	},
	(table) => [
		uniqueIndex("users_email_lower_unique").on(sql`lower(${table.email})`),
		check(
			"users_name_length_check",
			sql`char_length(${table.name}) between 1 and 50`,
		),
	],
);

export const sessions = pgTable(
	"sessions",
	{
		id: uuid("id").primaryKey().$defaultFn(uuidv7),
		userId: uuid("user_id")
			.notNull()
			.references(() => users.id, { onDelete: "cascade" }),
		tokenHash: text("token_hash").notNull().unique(),
		client: text("client").notNull().default("web"),
		deviceName: text("device_name"),
		expiresAt: timestamp("expires_at", { withTimezone: true }).notNull(),
		userAgent: text("user_agent"),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
		lastSeenAt: timestamp("last_seen_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
	},
	(table) => [
		check(
			"sessions_client_check",
			sql`${table.client} in ('web', 'ios', 'android')`,
		),
		check(
			"sessions_device_name_length_check",
			sql`${table.deviceName} is null or char_length(${table.deviceName}) between 1 and 60`,
		),
	],
);
