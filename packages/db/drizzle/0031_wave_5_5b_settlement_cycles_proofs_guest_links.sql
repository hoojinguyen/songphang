CREATE TABLE "settlement_cycles" (
	"id" uuid PRIMARY KEY NOT NULL,
	"group_id" uuid NOT NULL,
	"cycle_number" integer NOT NULL,
	"title" text NOT NULL,
	"started_at" timestamp with time zone NOT NULL,
	"closed_at" timestamp with time zone NOT NULL,
	"closed_by" uuid,
	"expense_count" integer DEFAULT 0 NOT NULL,
	"total_expense_amount" bigint DEFAULT 0 NOT NULL,
	"snapshot" jsonb NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "settlement_cycles_group_cycle_unique" UNIQUE("group_id","cycle_number"),
	CONSTRAINT "settlement_cycles_number_check" CHECK ("settlement_cycles"."cycle_number" >= 1),
	CONSTRAINT "settlement_cycles_title_check" CHECK (char_length("settlement_cycles"."title") between 1 and 80),
	CONSTRAINT "settlement_cycles_closed_at_check" CHECK ("settlement_cycles"."closed_at" >= "settlement_cycles"."started_at"),
	CONSTRAINT "settlement_cycles_expense_count_check" CHECK ("settlement_cycles"."expense_count" >= 0),
	CONSTRAINT "settlement_cycles_total_amount_check" CHECK ("settlement_cycles"."total_expense_amount" >= 0)
);
--> statement-breakpoint
ALTER TABLE "groups" ADD COLUMN "guest_token" text;--> statement-breakpoint
ALTER TABLE "groups" ADD COLUMN "guest_link_active" boolean DEFAULT false NOT NULL;--> statement-breakpoint
ALTER TABLE "groups" ADD COLUMN "guest_link_created_at" timestamp with time zone;--> statement-breakpoint
ALTER TABLE "transactions" ADD COLUMN "payment_channel" text;--> statement-breakpoint
ALTER TABLE "transactions" ADD COLUMN "payment_note" text;--> statement-breakpoint
ALTER TABLE "transactions" ADD COLUMN "cycle_id" uuid;--> statement-breakpoint
ALTER TABLE "settlement_requests" ADD COLUMN "channel" text;--> statement-breakpoint
ALTER TABLE "settlement_requests" ADD COLUMN "note" text;--> statement-breakpoint
ALTER TABLE "settlement_requests" ADD COLUMN "proof_attachment_id" uuid;--> statement-breakpoint
ALTER TABLE "settlement_cycles" ADD CONSTRAINT "settlement_cycles_group_id_groups_id_fk" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settlement_cycles" ADD CONSTRAINT "settlement_cycles_closed_by_users_id_fk" FOREIGN KEY ("closed_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "settlement_cycles_group_closed_idx" ON "settlement_cycles" USING btree ("group_id","cycle_number" DESC NULLS LAST);--> statement-breakpoint
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_cycle_id_settlement_cycles_id_fk" FOREIGN KEY ("cycle_id") REFERENCES "public"."settlement_cycles"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settlement_requests" ADD CONSTRAINT "settlement_requests_proof_attachment_id_attachments_id_fk" FOREIGN KEY ("proof_attachment_id") REFERENCES "public"."attachments"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "transactions_group_cycle_feed_idx" ON "transactions" USING btree ("group_id","cycle_id","occurred_at" DESC NULLS LAST,"id" DESC NULLS LAST) WHERE "transactions"."deleted_at" is null;--> statement-breakpoint
CREATE INDEX "settlement_requests_proof_attachment_idx" ON "settlement_requests" USING btree ("proof_attachment_id") WHERE "settlement_requests"."proof_attachment_id" is not null;--> statement-breakpoint
ALTER TABLE "groups" ADD CONSTRAINT "groups_guest_token_unique" UNIQUE("guest_token");--> statement-breakpoint
ALTER TABLE "groups" ADD CONSTRAINT "groups_guest_link_consistency_check" CHECK (("groups"."guest_link_active" = false and "groups"."guest_token" is null) or ("groups"."guest_link_active" = true and "groups"."guest_token" is not null and char_length("groups"."guest_token") >= 32));--> statement-breakpoint
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_payment_channel_check" CHECK ("transactions"."payment_channel" is null or ("transactions"."type" = 'transfer' and "transactions"."payment_channel" in ('bank', 'momo', 'zalopay', 'cash')));--> statement-breakpoint
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_payment_note_check" CHECK ("transactions"."payment_note" is null or ("transactions"."type" = 'transfer' and char_length("transactions"."payment_note") between 1 and 120));--> statement-breakpoint
ALTER TABLE "settlement_requests" ADD CONSTRAINT "settlement_channel_check" CHECK ("settlement_requests"."channel" is null or "settlement_requests"."channel" in ('bank', 'momo', 'zalopay', 'cash'));--> statement-breakpoint
ALTER TABLE "settlement_requests" ADD CONSTRAINT "settlement_note_check" CHECK ("settlement_requests"."note" is null or char_length("settlement_requests"."note") between 1 and 120);