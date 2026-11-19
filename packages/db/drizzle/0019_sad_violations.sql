CREATE TABLE "bot_drafts" (
	"id" uuid PRIMARY KEY NOT NULL,
	"chat_link_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"draft" jsonb NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"saved_transaction_id" uuid,
	"saved_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "bot_updates" (
	"platform" text NOT NULL,
	"update_id" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "bot_updates_platform_update_id_pk" PRIMARY KEY("platform","update_id"),
	CONSTRAINT "bot_updates_platform_check" CHECK (platform in ('telegram'))
);
--> statement-breakpoint
CREATE TABLE "chat_identities" (
	"platform" text NOT NULL,
	"platform_user_id" text NOT NULL,
	"user_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "chat_identities_platform_platform_user_id_pk" PRIMARY KEY("platform","platform_user_id"),
	CONSTRAINT "chat_identities_platform_check" CHECK (platform in ('telegram'))
);
--> statement-breakpoint
CREATE TABLE "chat_link_codes" (
	"code_hash" text PRIMARY KEY NOT NULL,
	"purpose" text NOT NULL,
	"group_id" uuid,
	"platform" text DEFAULT 'telegram' NOT NULL,
	"platform_user_id" text,
	"created_by" uuid,
	"expires_at" timestamp with time zone NOT NULL,
	"used_at" timestamp with time zone,
	CONSTRAINT "chat_link_codes_purpose_check" CHECK (purpose in ('group', 'user')),
	CONSTRAINT "chat_link_codes_platform_check" CHECK (platform in ('telegram')),
	CONSTRAINT "chat_link_codes_target_check" CHECK ((purpose = 'group' and group_id is not null and platform_user_id is null) or (purpose = 'user' and platform_user_id is not null and group_id is null))
);
--> statement-breakpoint
CREATE TABLE "chat_links" (
	"id" uuid PRIMARY KEY NOT NULL,
	"group_id" uuid NOT NULL,
	"platform" text NOT NULL,
	"chat_id" text NOT NULL,
	"linked_by" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "chat_links_platform_check" CHECK (platform in ('telegram'))
);
--> statement-breakpoint
ALTER TABLE "bot_drafts" ADD CONSTRAINT "bot_drafts_chat_link_id_chat_links_id_fk" FOREIGN KEY ("chat_link_id") REFERENCES "public"."chat_links"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bot_drafts" ADD CONSTRAINT "bot_drafts_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bot_drafts" ADD CONSTRAINT "bot_drafts_saved_transaction_id_transactions_id_fk" FOREIGN KEY ("saved_transaction_id") REFERENCES "public"."transactions"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "chat_identities" ADD CONSTRAINT "chat_identities_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "chat_link_codes" ADD CONSTRAINT "chat_link_codes_group_id_groups_id_fk" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "chat_link_codes" ADD CONSTRAINT "chat_link_codes_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "chat_links" ADD CONSTRAINT "chat_links_group_id_groups_id_fk" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "chat_links" ADD CONSTRAINT "chat_links_linked_by_users_id_fk" FOREIGN KEY ("linked_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "bot_drafts_chat_user_idx" ON "bot_drafts" USING btree ("chat_link_id","user_id","saved_at");--> statement-breakpoint
CREATE INDEX "bot_drafts_expires_idx" ON "bot_drafts" USING btree ("expires_at");--> statement-breakpoint
CREATE INDEX "bot_updates_created_idx" ON "bot_updates" USING btree ("created_at");--> statement-breakpoint
CREATE INDEX "chat_identities_user_idx" ON "chat_identities" USING btree ("user_id");--> statement-breakpoint
CREATE UNIQUE INDEX "chat_identities_platform_user_id_idx" ON "chat_identities" USING btree ("platform","user_id");--> statement-breakpoint
CREATE INDEX "chat_link_codes_expires_idx" ON "chat_link_codes" USING btree ("expires_at");--> statement-breakpoint
CREATE UNIQUE INDEX "chat_links_platform_chat_idx" ON "chat_links" USING btree ("platform","chat_id");--> statement-breakpoint
CREATE INDEX "chat_links_group_idx" ON "chat_links" USING btree ("group_id");