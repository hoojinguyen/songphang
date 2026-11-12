CREATE TABLE "group_users" (
	"group_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"role" text NOT NULL,
	"member_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "group_users_group_id_user_id_pk" PRIMARY KEY("group_id","user_id"),
	CONSTRAINT "group_users_member_unique" UNIQUE("group_id","member_id"),
	CONSTRAINT "group_users_role_check" CHECK ("group_users"."role" in ('owner', 'editor', 'viewer'))
);
--> statement-breakpoint
CREATE TABLE "groups" (
	"id" uuid PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"currency" text DEFAULT 'VND' NOT NULL,
	"minimize_debts" boolean DEFAULT true NOT NULL,
	"invite_token" text NOT NULL,
	"invite_active" boolean DEFAULT true NOT NULL,
	"default_role" text DEFAULT 'editor' NOT NULL,
	"created_by" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "groups_invite_token_unique" UNIQUE("invite_token"),
	CONSTRAINT "groups_name_length_check" CHECK (char_length("groups"."name") between 1 and 80),
	CONSTRAINT "groups_default_role_check" CHECK ("groups"."default_role" in ('editor', 'viewer'))
);
--> statement-breakpoint
CREATE TABLE "members" (
	"id" uuid PRIMARY KEY NOT NULL,
	"group_id" uuid NOT NULL,
	"name" text NOT NULL,
	"active" boolean DEFAULT true NOT NULL,
	"default_weight" numeric(6, 2) DEFAULT '1' NOT NULL,
	"position" integer NOT NULL,
	"shape" text NOT NULL,
	"color" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "members_group_position_unique" UNIQUE("group_id","position"),
	CONSTRAINT "members_name_length_check" CHECK (char_length("members"."name") between 1 and 50),
	CONSTRAINT "members_default_weight_check" CHECK ("members"."default_weight" >= 0),
	CONSTRAINT "members_shape_check" CHECK ("members"."shape" in ('circle', 'diamond', 'squircle', 'leaf')),
	CONSTRAINT "members_color_check" CHECK ("members"."color" in ('mint', 'sky', 'coral', 'lilac'))
);
--> statement-breakpoint
CREATE TABLE "transaction_payers" (
	"transaction_id" uuid NOT NULL,
	"member_id" uuid NOT NULL,
	"amount" bigint NOT NULL,
	CONSTRAINT "transaction_payers_transaction_id_member_id_pk" PRIMARY KEY("transaction_id","member_id"),
	CONSTRAINT "transaction_payers_amount_check" CHECK ("transaction_payers"."amount" > 0)
);
--> statement-breakpoint
CREATE TABLE "transaction_shares" (
	"transaction_id" uuid NOT NULL,
	"member_id" uuid NOT NULL,
	"amount" bigint NOT NULL,
	CONSTRAINT "transaction_shares_transaction_id_member_id_pk" PRIMARY KEY("transaction_id","member_id"),
	CONSTRAINT "transaction_shares_amount_check" CHECK ("transaction_shares"."amount" >= 0)
);
--> statement-breakpoint
CREATE TABLE "transactions" (
	"id" uuid PRIMARY KEY NOT NULL,
	"group_id" uuid NOT NULL,
	"type" text NOT NULL,
	"description" text NOT NULL,
	"amount" bigint NOT NULL,
	"currency" text NOT NULL,
	"occurred_at" timestamp with time zone NOT NULL,
	"category" text,
	"split_method" text NOT NULL,
	"split_input" jsonb NOT NULL,
	"version" integer DEFAULT 1 NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp with time zone,
	CONSTRAINT "transactions_type_check" CHECK ("transactions"."type" in ('expense', 'transfer', 'income')),
	CONSTRAINT "transactions_description_check" CHECK (char_length("transactions"."description") between 1 and 200),
	CONSTRAINT "transactions_amount_check" CHECK ("transactions"."amount" between 1 and 999999999999),
	CONSTRAINT "transactions_category_check" CHECK ("transactions"."category" is null or "transactions"."category" in ('food', 'transport', 'lodging', 'shopping', 'entertainment', 'bills', 'other')),
	CONSTRAINT "transactions_split_method_check" CHECK ("transactions"."split_method" in ('equal', 'exact', 'shares', 'percent'))
);
--> statement-breakpoint
CREATE TABLE "activity_log" (
	"id" uuid PRIMARY KEY NOT NULL,
	"group_id" uuid NOT NULL,
	"actor_user_id" uuid,
	"action" text NOT NULL,
	"entity_type" text NOT NULL,
	"entity_id" uuid,
	"summary" text NOT NULL,
	"before" jsonb,
	"after" jsonb,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "idempotency_keys" (
	"user_id" uuid NOT NULL,
	"key" text NOT NULL,
	"request_hash" text NOT NULL,
	"response_status" integer NOT NULL,
	"response_body" jsonb NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "idempotency_keys_user_id_key_pk" PRIMARY KEY("user_id","key")
);
--> statement-breakpoint
ALTER TABLE "group_users" ADD CONSTRAINT "group_users_group_id_groups_id_fk" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "group_users" ADD CONSTRAINT "group_users_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "group_users" ADD CONSTRAINT "group_users_member_id_members_id_fk" FOREIGN KEY ("member_id") REFERENCES "public"."members"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "groups" ADD CONSTRAINT "groups_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "members" ADD CONSTRAINT "members_group_id_groups_id_fk" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transaction_payers" ADD CONSTRAINT "transaction_payers_transaction_id_transactions_id_fk" FOREIGN KEY ("transaction_id") REFERENCES "public"."transactions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transaction_payers" ADD CONSTRAINT "transaction_payers_member_id_members_id_fk" FOREIGN KEY ("member_id") REFERENCES "public"."members"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transaction_shares" ADD CONSTRAINT "transaction_shares_transaction_id_transactions_id_fk" FOREIGN KEY ("transaction_id") REFERENCES "public"."transactions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transaction_shares" ADD CONSTRAINT "transaction_shares_member_id_members_id_fk" FOREIGN KEY ("member_id") REFERENCES "public"."members"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_group_id_groups_id_fk" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_updated_by_users_id_fk" FOREIGN KEY ("updated_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "activity_log" ADD CONSTRAINT "activity_log_group_id_groups_id_fk" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "activity_log" ADD CONSTRAINT "activity_log_actor_user_id_users_id_fk" FOREIGN KEY ("actor_user_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "idempotency_keys" ADD CONSTRAINT "idempotency_keys_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "group_users_owner_unique" ON "group_users" USING btree ("group_id") WHERE "group_users"."role" = 'owner';--> statement-breakpoint
CREATE INDEX "transactions_group_feed_index" ON "transactions" USING btree ("group_id","occurred_at" DESC NULLS LAST,"id" DESC NULLS LAST) WHERE "transactions"."deleted_at" is null;--> statement-breakpoint
CREATE INDEX "activity_log_group_created_index" ON "activity_log" USING btree ("group_id","created_at" DESC NULLS LAST);