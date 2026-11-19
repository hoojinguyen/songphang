ALTER TABLE "groups" ADD COLUMN "approval_threshold" bigint;--> statement-breakpoint
ALTER TABLE "transactions" ADD COLUMN "approval_status" text DEFAULT 'none' NOT NULL;--> statement-breakpoint
ALTER TABLE "transactions" ADD COLUMN "approval_decided_by" uuid;--> statement-breakpoint
ALTER TABLE "transactions" ADD COLUMN "approval_decided_at" timestamp with time zone;--> statement-breakpoint
ALTER TABLE "transactions" ADD COLUMN "approval_note" text;--> statement-breakpoint
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_approval_decided_by_users_id_fk" FOREIGN KEY ("approval_decided_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "groups" ADD CONSTRAINT "groups_approval_threshold_check" CHECK ("groups"."approval_threshold" is null or "groups"."approval_threshold" > 0);--> statement-breakpoint
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_approval_status_check" CHECK ("transactions"."approval_status" in ('none', 'pending', 'approved', 'rejected'));--> statement-breakpoint
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_approval_note_check" CHECK ("transactions"."approval_note" is null or char_length("transactions"."approval_note") <= 300);