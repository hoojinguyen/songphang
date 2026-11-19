import type { ReceiptCheckFlag } from "@songphang/core";
import { sql } from "drizzle-orm";
import {
	check,
	index,
	jsonb,
	pgTable,
	text,
	timestamp,
	uuid,
} from "drizzle-orm/pg-core";
import { uuidv7 } from "uuidv7";
import { users } from "./schema.js";
import { attachments } from "./schema-attachments.js";
import { groups } from "./schema-groups.js";

export type StoredReceiptReading = {
	merchant: string | null;
	occurredOn: string | null;
	items: Array<{
		name: string;
		quantity: number;
		amount: number;
	}>;
	extras: Array<{
		kind: "tax" | "service" | "discount" | "other";
		label: string;
		amount: number;
	}>;
	total: number | null;
};

export type StoredReceiptScanResult = {
	reading: StoredReceiptReading;
	computed: number;
	flags: ReceiptCheckFlag[];
};

export const receiptScans = pgTable(
	"receipt_scans",
	{
		id: uuid("id").primaryKey().$defaultFn(uuidv7),
		groupId: uuid("group_id")
			.notNull()
			.references(() => groups.id, { onDelete: "cascade" }),
		attachmentId: uuid("attachment_id")
			.notNull()
			.unique()
			.references(() => attachments.id, { onDelete: "cascade" }),
		status: text("status").notNull().default("queued"),
		result: jsonb("result").$type<StoredReceiptScanResult | null>(),
		errorCode: text("error_code"),
		createdBy: uuid("created_by").references(() => users.id, {
			onDelete: "set null",
		}),
		createdAt: timestamp("created_at", { withTimezone: true })
			.notNull()
			.defaultNow(),
		finishedAt: timestamp("finished_at", { withTimezone: true }),
	},
	(table) => [
		check(
			"receipt_scans_status_check",
			sql`${table.status} in ('queued', 'processing', 'done', 'failed')`,
		),
		index("receipt_scans_group_index").on(table.groupId, table.createdAt),
		index("receipt_scans_status_created_index").on(
			table.status,
			table.createdAt,
		),
	],
);
