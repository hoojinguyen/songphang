CREATE TABLE "receipt_scans" (
	"id" uuid PRIMARY KEY NOT NULL,
	"group_id" uuid NOT NULL,
	"attachment_id" uuid NOT NULL,
	"status" text DEFAULT 'queued' NOT NULL,
	"result" jsonb,
	"error_code" text,
	"created_by" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"finished_at" timestamp with time zone,
	CONSTRAINT "receipt_scans_attachment_id_unique" UNIQUE("attachment_id"),
	CONSTRAINT "receipt_scans_status_check" CHECK ("receipt_scans"."status" in ('queued', 'processing', 'done', 'failed'))
);
--> statement-breakpoint
ALTER TABLE "ai_calls" ADD COLUMN "receipt_scan_id" uuid;--> statement-breakpoint
ALTER TABLE "receipt_scans" ADD CONSTRAINT "receipt_scans_group_id_groups_id_fk" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "receipt_scans" ADD CONSTRAINT "receipt_scans_attachment_id_attachments_id_fk" FOREIGN KEY ("attachment_id") REFERENCES "public"."attachments"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "receipt_scans" ADD CONSTRAINT "receipt_scans_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "receipt_scans_group_index" ON "receipt_scans" USING btree ("group_id","created_at");--> statement-breakpoint
CREATE INDEX "receipt_scans_status_created_index" ON "receipt_scans" USING btree ("status","created_at");--> statement-breakpoint
ALTER TABLE "ai_calls" ADD CONSTRAINT "ai_calls_receipt_scan_id_receipt_scans_id_fk" FOREIGN KEY ("receipt_scan_id") REFERENCES "public"."receipt_scans"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "ai_calls_scan_index" ON "ai_calls" USING btree ("receipt_scan_id");