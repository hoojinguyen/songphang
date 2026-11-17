ALTER TABLE "transactions" ADD COLUMN "description_search" text DEFAULT '' NOT NULL;--> statement-breakpoint
UPDATE "transactions" SET "description_search" = lower("description");