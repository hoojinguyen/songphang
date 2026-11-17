CREATE TABLE "settlement_requests" (
	"id" uuid PRIMARY KEY NOT NULL,
	"group_id" uuid NOT NULL,
	"from_member_id" uuid NOT NULL,
	"to_member_id" uuid NOT NULL,
	"amount" bigint NOT NULL,
	"status" text DEFAULT 'pending' NOT NULL,
	"transaction_id" uuid,
	"created_by" uuid,
	"resolved_by" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"resolved_at" timestamp with time zone,
	CONSTRAINT "settlement_amount_check" CHECK ("settlement_requests"."amount" between 1 and 999999999999),
	CONSTRAINT "settlement_members_check" CHECK ("settlement_requests"."from_member_id" <> "settlement_requests"."to_member_id"),
	CONSTRAINT "settlement_status_check" CHECK ("settlement_requests"."status" in ('pending','confirmed','rejected','cancelled'))
);
--> statement-breakpoint
ALTER TABLE "settlement_requests" ADD CONSTRAINT "settlement_requests_group_id_groups_id_fk" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settlement_requests" ADD CONSTRAINT "settlement_requests_from_member_id_members_id_fk" FOREIGN KEY ("from_member_id") REFERENCES "public"."members"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settlement_requests" ADD CONSTRAINT "settlement_requests_to_member_id_members_id_fk" FOREIGN KEY ("to_member_id") REFERENCES "public"."members"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settlement_requests" ADD CONSTRAINT "settlement_requests_transaction_id_transactions_id_fk" FOREIGN KEY ("transaction_id") REFERENCES "public"."transactions"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settlement_requests" ADD CONSTRAINT "settlement_requests_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settlement_requests" ADD CONSTRAINT "settlement_requests_resolved_by_users_id_fk" FOREIGN KEY ("resolved_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "settlement_pending_pair_unique" ON "settlement_requests" USING btree ("group_id","from_member_id","to_member_id") WHERE "settlement_requests"."status" = 'pending';