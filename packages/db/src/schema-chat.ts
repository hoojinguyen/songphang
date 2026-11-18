import { sql } from "drizzle-orm";
import {
	check,
	index,
	jsonb,
	pgTable,
	primaryKey,
	text,
	timestamp,
	uniqueIndex,
	uuid,
} from "drizzle-orm/pg-core";
import { users } from "./schema.js";
import { groups } from "./schema-groups.js";
import { transactions } from "./schema-transactions.js";

export const chatLinks = pgTable(
	"chat_links",
	{
		id: uuid("id").primaryKey(),
		groupId: uuid("group_id")
			.notNull()
			.references(() => groups.id, { onDelete: "cascade" }),
		platform: text("platform").notNull(),
		chatId: text("chat_id").notNull(),
		linkedBy: uuid("linked_by").references(() => users.id, {
			onDelete: "set null",
		}),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
	},
	(table) => [
		uniqueIndex("chat_links_platform_chat_idx").on(
			table.platform,
			table.chatId,
		),
		index("chat_links_group_idx").on(table.groupId),
		check("chat_links_platform_check", sql`platform in ('telegram')`),
	],
);

export const chatIdentities = pgTable(
	"chat_identities",
	{
		platform: text("platform").notNull(),
		platformUserId: text("platform_user_id").notNull(),
		userId: uuid("user_id")
			.notNull()
			.references(() => users.id, { onDelete: "cascade" }),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
	},
	(table) => [
		primaryKey({ columns: [table.platform, table.platformUserId] }),
		index("chat_identities_user_idx").on(table.userId),
		uniqueIndex("chat_identities_platform_user_id_idx").on(
			table.platform,
			table.userId,
		),
		check("chat_identities_platform_check", sql`platform in ('telegram')`),
	],
);

export const chatLinkCodes = pgTable(
	"chat_link_codes",
	{
		codeHash: text("code_hash").primaryKey(),
		purpose: text("purpose").notNull(),
		groupId: uuid("group_id").references(() => groups.id, {
			onDelete: "cascade",
		}),
		platform: text("platform").notNull().default("telegram"),
		platformUserId: text("platform_user_id"),
		createdBy: uuid("created_by").references(() => users.id, {
			onDelete: "cascade",
		}),
		expiresAt: timestamp("expires_at", { withTimezone: true }).notNull(),
		usedAt: timestamp("used_at", { withTimezone: true }),
	},
	(table) => [
		index("chat_link_codes_expires_idx").on(table.expiresAt),
		check("chat_link_codes_purpose_check", sql`purpose in ('group', 'user')`),
		check("chat_link_codes_platform_check", sql`platform in ('telegram')`),
		check(
			"chat_link_codes_target_check",
			sql`(purpose = 'group' and group_id is not null and platform_user_id is null) or (purpose = 'user' and platform_user_id is not null and group_id is null)`,
		),
	],
);

export const botDrafts = pgTable(
	"bot_drafts",
	{
		id: uuid("id").primaryKey(),
		chatLinkId: uuid("chat_link_id")
			.notNull()
			.references(() => chatLinks.id, { onDelete: "cascade" }),
		userId: uuid("user_id")
			.notNull()
			.references(() => users.id, { onDelete: "cascade" }),
		draft: jsonb("draft").$type<Record<string, unknown>>().notNull(),
		expiresAt: timestamp("expires_at", { withTimezone: true }).notNull(),
		savedTransactionId: uuid("saved_transaction_id").references(
			() => transactions.id,
			{ onDelete: "set null" },
		),
		savedAt: timestamp("saved_at", { withTimezone: true }),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
	},
	(table) => [
		index("bot_drafts_chat_user_idx").on(
			table.chatLinkId,
			table.userId,
			table.savedAt,
		),
		index("bot_drafts_expires_idx").on(table.expiresAt),
	],
);

export const botUpdates = pgTable(
	"bot_updates",
	{
		platform: text("platform").notNull(),
		updateId: text("update_id").notNull(),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
	},
	(table) => [
		primaryKey({ columns: [table.platform, table.updateId] }),
		index("bot_updates_created_idx").on(table.createdAt),
		check("bot_updates_platform_check", sql`platform in ('telegram')`),
	],
);
