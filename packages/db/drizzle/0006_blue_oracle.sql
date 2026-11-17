CREATE TABLE "group_categories" (
	"id" uuid PRIMARY KEY NOT NULL,
	"group_id" uuid NOT NULL,
	"name" text NOT NULL,
	"name_key" text NOT NULL,
	"color" text NOT NULL,
	"archived_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "group_categories_name_length_check" CHECK (char_length("group_categories"."name") between 1 and 30),
	CONSTRAINT "group_categories_color_check" CHECK ("group_categories"."color" in ('mint', 'sky', 'coral', 'lilac'))
);
--> statement-breakpoint
ALTER TABLE "transactions" ADD COLUMN "category_id" uuid;--> statement-breakpoint
ALTER TABLE "group_categories" ADD CONSTRAINT "group_categories_group_id_groups_id_fk" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "group_categories_live_name_unique" ON "group_categories" USING btree ("group_id","name_key") WHERE "group_categories"."archived_at" is null;--> statement-breakpoint
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_category_id_group_categories_id_fk" FOREIGN KEY ("category_id") REFERENCES "public"."group_categories"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_category_exclusive_check" CHECK ("transactions"."category" is null or "transactions"."category_id" is null);