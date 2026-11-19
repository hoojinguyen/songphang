CREATE TABLE "chat_identity_pairings" (
	"id" uuid PRIMARY KEY NOT NULL,
	"platform" text DEFAULT 'telegram' NOT NULL,
	"user_id" uuid NOT NULL,
	"session_id" uuid NOT NULL,
	"secret_hash" text NOT NULL,
	"status" text DEFAULT 'pending_telegram' NOT NULL,
	"platform_user_id" text,
	"platform_user_name" text,
	"telegram_confirmed_at" timestamp with time zone,
	"expires_at" timestamp with time zone NOT NULL,
	"consumed_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "chat_identity_pairings_secret_hash_unique" UNIQUE("secret_hash"),
	CONSTRAINT "chat_identity_pairings_platform_check" CHECK (platform in ('telegram')),
	CONSTRAINT "chat_identity_pairings_status_check" CHECK (status in ('pending_telegram', 'telegram_confirmed', 'completed', 'cancelled'))
);
--> statement-breakpoint
ALTER TABLE "chat_link_codes" DROP CONSTRAINT "chat_link_codes_purpose_check";--> statement-breakpoint
ALTER TABLE "chat_link_codes" DROP CONSTRAINT "chat_link_codes_target_check";--> statement-breakpoint
ALTER TABLE "chat_identity_pairings" ADD CONSTRAINT "chat_identity_pairings_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "chat_identity_pairings" ADD CONSTRAINT "chat_identity_pairings_session_id_sessions_id_fk" FOREIGN KEY ("session_id") REFERENCES "public"."sessions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "chat_identity_pairings_user_idx" ON "chat_identity_pairings" USING btree ("user_id","created_at" DESC NULLS LAST);--> statement-breakpoint
CREATE INDEX "chat_identity_pairings_expires_idx" ON "chat_identity_pairings" USING btree ("expires_at");--> statement-breakpoint
DELETE FROM "chat_link_codes" WHERE "purpose" = 'user';--> statement-breakpoint
DELETE FROM "chat_identities";--> statement-breakpoint
ALTER TABLE "chat_link_codes" ADD CONSTRAINT "chat_link_codes_purpose_check" CHECK (purpose in ('group'));--> statement-breakpoint
ALTER TABLE "chat_link_codes" ADD CONSTRAINT "chat_link_codes_target_check" CHECK (purpose = 'group' and group_id is not null and platform_user_id is null);