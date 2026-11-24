ALTER TABLE "groups" ADD COLUMN "archived_at" timestamp with time zone;--> statement-breakpoint
CREATE INDEX "groups_archived_at_idx" ON "groups" USING btree ("archived_at");