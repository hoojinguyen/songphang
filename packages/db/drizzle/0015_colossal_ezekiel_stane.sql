CREATE TABLE "transaction_disputes" (
	"id" uuid PRIMARY KEY NOT NULL,
	"group_id" uuid NOT NULL,
	"transaction_id" uuid NOT NULL,
	"reason" text NOT NULL,
	"opened_by" uuid,
	"opened_by_name" text NOT NULL,
	"opened_at" timestamp with time zone DEFAULT now() NOT NULL,
	"resolved_by" uuid,
	"resolved_at" timestamp with time zone,
	CONSTRAINT "transaction_disputes_reason_check" CHECK (char_length("transaction_disputes"."reason") between 1 and 500),
	CONSTRAINT "transaction_disputes_opened_by_name_check" CHECK (char_length("transaction_disputes"."opened_by_name") between 1 and 50)
);
--> statement-breakpoint
ALTER TABLE "transaction_disputes" ADD CONSTRAINT "transaction_disputes_group_id_groups_id_fk" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transaction_disputes" ADD CONSTRAINT "transaction_disputes_transaction_id_transactions_id_fk" FOREIGN KEY ("transaction_id") REFERENCES "public"."transactions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transaction_disputes" ADD CONSTRAINT "transaction_disputes_opened_by_users_id_fk" FOREIGN KEY ("opened_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transaction_disputes" ADD CONSTRAINT "transaction_disputes_resolved_by_users_id_fk" FOREIGN KEY ("resolved_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "transaction_disputes_open_unique" ON "transaction_disputes" USING btree ("transaction_id") WHERE "transaction_disputes"."resolved_at" is null;