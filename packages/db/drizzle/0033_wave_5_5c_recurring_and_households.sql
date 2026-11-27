CREATE TABLE "households" (
	"id" uuid PRIMARY KEY NOT NULL,
	"group_id" uuid NOT NULL,
	"name" text NOT NULL,
	"representative_member_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "households_name_length_check" CHECK (char_length("households"."name") between 1 and 50)
);
--> statement-breakpoint
CREATE TABLE "recurring_expenses" (
	"id" uuid PRIMARY KEY NOT NULL,
	"group_id" uuid NOT NULL,
	"mode" text NOT NULL,
	"active" boolean DEFAULT true NOT NULL,
	"description" text NOT NULL,
	"amount" bigint,
	"category" text,
	"category_id" uuid,
	"payers_template" jsonb NOT NULL,
	"split_template" jsonb NOT NULL,
	"frequency" text NOT NULL,
	"day_of_week" integer,
	"day_of_month" integer,
	"month_of_year" integer,
	"next_due_date" date NOT NULL,
	"pending_due_date" date,
	"last_processed_due_date" date,
	"last_posted_at" timestamp with time zone,
	"last_transaction_id" uuid,
	"pause_reason" text,
	"created_by" uuid,
	"updated_by" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "recurring_expenses_mode_check" CHECK ("recurring_expenses"."mode" in ('fixed', 'variable')),
	CONSTRAINT "recurring_expenses_description_check" CHECK (char_length("recurring_expenses"."description") between 1 and 200),
	CONSTRAINT "recurring_expenses_amount_check" CHECK (("recurring_expenses"."mode" = 'fixed' and "recurring_expenses"."amount" is not null and "recurring_expenses"."amount" > 0) or ("recurring_expenses"."mode" = 'variable' and ("recurring_expenses"."amount" is null or "recurring_expenses"."amount" > 0))),
	CONSTRAINT "recurring_expenses_category_check" CHECK ("recurring_expenses"."category" is null or "recurring_expenses"."category" in ('food', 'transport', 'lodging', 'shopping', 'entertainment', 'bills', 'other')),
	CONSTRAINT "recurring_expenses_category_exclusive_check" CHECK ("recurring_expenses"."category" is null or "recurring_expenses"."category_id" is null),
	CONSTRAINT "recurring_expenses_frequency_check" CHECK ("recurring_expenses"."frequency" in ('weekly', 'monthly', 'quarterly', 'yearly')),
	CONSTRAINT "recurring_expenses_day_of_week_check" CHECK ("recurring_expenses"."day_of_week" is null or "recurring_expenses"."day_of_week" between 1 and 7),
	CONSTRAINT "recurring_expenses_day_of_month_check" CHECK ("recurring_expenses"."day_of_month" is null or "recurring_expenses"."day_of_month" between 1 and 31),
	CONSTRAINT "recurring_expenses_month_of_year_check" CHECK ("recurring_expenses"."month_of_year" is null or "recurring_expenses"."month_of_year" between 1 and 12),
	CONSTRAINT "recurring_expenses_pause_reason_check" CHECK ("recurring_expenses"."pause_reason" is null or "recurring_expenses"."pause_reason" in ('member_invalid', 'split_invalid')),
	CONSTRAINT "recurring_expenses_schedule_fields_check" CHECK (("recurring_expenses"."frequency" = 'weekly' and "recurring_expenses"."day_of_week" is not null and "recurring_expenses"."day_of_month" is null and "recurring_expenses"."month_of_year" is null) or ("recurring_expenses"."frequency" in ('monthly', 'quarterly') and "recurring_expenses"."day_of_month" is not null and "recurring_expenses"."day_of_week" is null and "recurring_expenses"."month_of_year" is null) or ("recurring_expenses"."frequency" = 'yearly' and "recurring_expenses"."day_of_month" is not null and "recurring_expenses"."month_of_year" is not null and "recurring_expenses"."day_of_week" is null)),
	CONSTRAINT "recurring_expenses_pending_mode_check" CHECK ("recurring_expenses"."mode" = 'variable' or "recurring_expenses"."pending_due_date" is null)
);
--> statement-breakpoint
ALTER TABLE "members" ADD COLUMN "household_id" uuid;--> statement-breakpoint
ALTER TABLE "transactions" ADD COLUMN "recurring_expense_id" uuid;--> statement-breakpoint
ALTER TABLE "households" ADD CONSTRAINT "households_group_id_groups_id_fk" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "households" ADD CONSTRAINT "households_representative_member_id_members_id_fk" FOREIGN KEY ("representative_member_id") REFERENCES "public"."members"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "recurring_expenses" ADD CONSTRAINT "recurring_expenses_group_id_groups_id_fk" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "recurring_expenses" ADD CONSTRAINT "recurring_expenses_category_id_group_categories_id_fk" FOREIGN KEY ("category_id") REFERENCES "public"."group_categories"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "recurring_expenses" ADD CONSTRAINT "recurring_expenses_last_transaction_id_transactions_id_fk" FOREIGN KEY ("last_transaction_id") REFERENCES "public"."transactions"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "recurring_expenses" ADD CONSTRAINT "recurring_expenses_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "recurring_expenses" ADD CONSTRAINT "recurring_expenses_updated_by_users_id_fk" FOREIGN KEY ("updated_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "households_group_idx" ON "households" USING btree ("group_id","created_at");--> statement-breakpoint
CREATE UNIQUE INDEX "households_representative_unique" ON "households" USING btree ("representative_member_id");--> statement-breakpoint
CREATE INDEX "recurring_expenses_group_idx" ON "recurring_expenses" USING btree ("group_id","created_at" DESC NULLS LAST);--> statement-breakpoint
CREATE INDEX "recurring_expenses_due_idx" ON "recurring_expenses" USING btree ("next_due_date") WHERE "recurring_expenses"."active" = true;--> statement-breakpoint
CREATE INDEX "recurring_expenses_pending_idx" ON "recurring_expenses" USING btree ("group_id","pending_due_date") WHERE "recurring_expenses"."pending_due_date" is not null;--> statement-breakpoint
ALTER TABLE "members" ADD CONSTRAINT "members_household_id_households_id_fk" FOREIGN KEY ("household_id") REFERENCES "public"."households"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_recurring_expense_id_recurring_expenses_id_fk" FOREIGN KEY ("recurring_expense_id") REFERENCES "public"."recurring_expenses"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "members_group_household_idx" ON "members" USING btree ("group_id","household_id") WHERE "members"."household_id" is not null;--> statement-breakpoint
CREATE INDEX "transactions_recurring_expense_idx" ON "transactions" USING btree ("recurring_expense_id") WHERE "transactions"."recurring_expense_id" is not null;--> statement-breakpoint
ALTER TABLE "members" ADD CONSTRAINT "members_household_person_check" CHECK ("members"."kind" = 'person' or "members"."household_id" is null);