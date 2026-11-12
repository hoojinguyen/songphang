import {
	index,
	integer,
	jsonb,
	pgTable,
	primaryKey,
	text,
	timestamp,
	uuid,
} from "drizzle-orm/pg-core";
import { uuidv7 } from "uuidv7";
import { users } from "./schema.js";
import { groups } from "./schema-groups.js";

export const activityLog = pgTable(
	"activity_log",
	{
		id: uuid("id").primaryKey().$defaultFn(uuidv7),
		groupId: uuid("group_id")
			.notNull()
			.references(() => groups.id, { onDelete: "cascade" }),
		actorUserId: uuid("actor_user_id").references(() => users.id, {
			onDelete: "set null",
		}),
		action: text("action").notNull(),
		entityType: text("entity_type").notNull(),
		entityId: uuid("entity_id"),
		summary: text("summary").notNull(),
		before: jsonb("before").$type<unknown>(),
		after: jsonb("after").$type<unknown>(),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
	},
	(table) => [
		index("activity_log_group_created_index").on(
			table.groupId,
			table.createdAt.desc(),
		),
	],
);

export const idempotencyKeys = pgTable(
	"idempotency_keys",
	{
		userId: uuid("user_id")
			.notNull()
			.references(() => users.id, { onDelete: "cascade" }),
		key: text("key").notNull(),
		requestHash: text("request_hash").notNull(),
		responseStatus: integer("response_status").notNull(),
		responseBody: jsonb("response_body").$type<unknown>().notNull(),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
	},
	(table) => [primaryKey({ columns: [table.userId, table.key] })],
);
