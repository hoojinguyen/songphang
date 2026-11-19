CREATE TABLE "debt_reminders" (
	"id" uuid PRIMARY KEY NOT NULL,
	"group_id" uuid NOT NULL,
	"from_member_id" uuid NOT NULL,
	"to_member_id" uuid NOT NULL,
	"amount" bigint NOT NULL,
	"sent_by" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "debt_reminders_amount_check" CHECK ("debt_reminders"."amount" > 0)
);
--> statement-breakpoint
ALTER TABLE "groups" ADD COLUMN "reminder_interval_days" integer;--> statement-breakpoint
ALTER TABLE "debt_reminders" ADD CONSTRAINT "debt_reminders_group_id_groups_id_fk" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "debt_reminders" ADD CONSTRAINT "debt_reminders_from_member_id_members_id_fk" FOREIGN KEY ("from_member_id") REFERENCES "public"."members"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "debt_reminders" ADD CONSTRAINT "debt_reminders_to_member_id_members_id_fk" FOREIGN KEY ("to_member_id") REFERENCES "public"."members"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "debt_reminders" ADD CONSTRAINT "debt_reminders_sent_by_users_id_fk" FOREIGN KEY ("sent_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "debt_reminders_pair_created_index" ON "debt_reminders" USING btree ("group_id","from_member_id","to_member_id","created_at" DESC NULLS LAST);--> statement-breakpoint
ALTER TABLE "groups" ADD CONSTRAINT "groups_reminder_interval_days_check" CHECK ("groups"."reminder_interval_days" is null or "groups"."reminder_interval_days" in (3, 7, 14));