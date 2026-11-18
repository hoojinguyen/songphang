import { sql } from "drizzle-orm";
import {
	type AnyPgColumn,
	bigint,
	boolean,
	check,
	integer,
	numeric,
	pgTable,
	primaryKey,
	text,
	timestamp,
	unique,
	uniqueIndex,
	uuid,
} from "drizzle-orm/pg-core";
import { uuidv7 } from "uuidv7";
import { users } from "./schema.js";

export const groups = pgTable(
	"groups",
	{
		id: uuid("id").primaryKey().$defaultFn(uuidv7),
		name: text("name").notNull(),
		currency: text("currency").notNull().default("VND"),
		minimizeDebts: boolean("minimize_debts").notNull().default(true),
		inviteToken: text("invite_token").notNull().unique(),
		inviteActive: boolean("invite_active").notNull().default(true),
		defaultRole: text("default_role").notNull().default("editor"),
		reminderIntervalDays: integer("reminder_interval_days"),
		approvalThreshold: bigint("approval_threshold", { mode: "number" }),
		createdBy: uuid("created_by").references(() => users.id, {
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
		check(
			"groups_name_length_check",
			sql`char_length(${table.name}) between 1 and 80`,
		),
		check(
			"groups_default_role_check",
			sql`${table.defaultRole} in ('editor', 'viewer')`,
		),
		check(
			"groups_reminder_interval_days_check",
			sql`${table.reminderIntervalDays} is null or ${table.reminderIntervalDays} in (3, 7, 14)`,
		),
		check(
			"groups_approval_threshold_check",
			sql`${table.approvalThreshold} is null or ${table.approvalThreshold} > 0`,
		),
	],
);

export const members = pgTable(
	"members",
	{
		id: uuid("id").primaryKey().$defaultFn(uuidv7),
		groupId: uuid("group_id")
			.notNull()
			.references(() => groups.id, { onDelete: "cascade" }),
		name: text("name").notNull(),
		kind: text("kind").notNull().default("person"),
		fundHolderMemberId: uuid("fund_holder_member_id").references(
			(): AnyPgColumn => members.id,
			{ onDelete: "set null" },
		),
		active: boolean("active").notNull().default(true),
		defaultWeight: numeric("default_weight", { precision: 6, scale: 2 })
			.notNull()
			.default("1"),
		position: integer("position").notNull(),
		shape: text("shape").notNull(),
		color: text("color").notNull(),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
		updatedAt: timestamp("updated_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
	},
	(table) => [
		unique("members_group_position_unique").on(table.groupId, table.position),
		uniqueIndex("members_group_fund_unique")
			.on(table.groupId)
			.where(sql`${table.kind} = 'fund'`),
		check("members_kind_check", sql`${table.kind} in ('person', 'fund')`),
		check(
			"members_fund_holder_kind_check",
			sql`${table.kind} = 'fund' or ${table.fundHolderMemberId} is null`,
		),
		check(
			"members_name_length_check",
			sql`char_length(${table.name}) between 1 and 50`,
		),
		check("members_default_weight_check", sql`${table.defaultWeight} >= 0`),
		check(
			"members_shape_check",
			sql`${table.shape} in ('circle', 'diamond', 'squircle', 'leaf', 'fund')`,
		),
		check(
			"members_color_check",
			sql`${table.color} in ('mint', 'sky', 'coral', 'lilac', 'sun')`,
		),
	],
);

export const groupUsers = pgTable(
	"group_users",
	{
		groupId: uuid("group_id")
			.notNull()
			.references(() => groups.id, { onDelete: "cascade" }),
		userId: uuid("user_id")
			.notNull()
			.references(() => users.id, { onDelete: "cascade" }),
		role: text("role").notNull(),
		memberId: uuid("member_id").references(() => members.id, {
			onDelete: "set null",
		}),
		muted: boolean("muted").notNull().default(false),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
	},
	(table) => [
		primaryKey({ columns: [table.groupId, table.userId] }),
		unique("group_users_member_unique").on(table.groupId, table.memberId),
		uniqueIndex("group_users_owner_unique")
			.on(table.groupId)
			.where(sql`${table.role} = 'owner'`),
		check(
			"group_users_role_check",
			sql`${table.role} in ('owner', 'editor', 'viewer')`,
		),
	],
);
