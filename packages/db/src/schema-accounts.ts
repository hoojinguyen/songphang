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
import { users } from "./schema.js";
export const userIdentities = pgTable(
	"user_identities",
	{
		id: uuid("id").primaryKey().$defaultFn(uuidv7),
		userId: uuid("user_id")
			.notNull()
			.references(() => users.id, { onDelete: "cascade" }),
		provider: text("provider").$type<"google" | "password">().notNull(),
		providerSubject: text("provider_subject"),
		passwordHash: text("password_hash"),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
	},
	(table) => [
		unique("user_identities_provider_subject_unique").on(
			table.provider,
			table.providerSubject,
		),
		unique("user_identities_user_provider_unique").on(
			table.userId,
			table.provider,
		),
		check(
			"user_identities_provider_check",
			sql`${table.provider} in ('google','password')`,
		),
		check(
			"user_identities_credentials_check",
			sql`(${table.provider} = 'password' and ${table.passwordHash} is not null and ${table.providerSubject} is null) or (${table.provider} = 'google' and ${table.providerSubject} is not null and ${table.passwordHash} is null)`,
		),
	],
);
export const authTokens = pgTable(
	"auth_tokens",
	{
		id: uuid("id").primaryKey().$defaultFn(uuidv7),
		userId: uuid("user_id")
			.notNull()
			.references(() => users.id, { onDelete: "cascade" }),
		purpose: text("purpose")
			.$type<"verify_email" | "reset_password">()
			.notNull(),
		tokenHash: text("token_hash").notNull().unique(),
		expiresAt: timestamp("expires_at", { withTimezone: true }).notNull(),
		usedAt: timestamp("used_at", { withTimezone: true }),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
	},
	(table) => [
		check(
			"auth_tokens_purpose_check",
			sql`${table.purpose} in ('verify_email','reset_password')`,
		),
	],
);
