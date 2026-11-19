CREATE TABLE "notification_unsubscribe_tokens" (
	"id" uuid PRIMARY KEY NOT NULL,
	"user_id" uuid NOT NULL,
	"token_hash" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "notification_unsubscribe_tokens_token_hash_unique" UNIQUE("token_hash")
);
--> statement-breakpoint
ALTER TABLE "notification_unsubscribe_tokens" ADD CONSTRAINT "notification_unsubscribe_tokens_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "notification_unsubscribe_tokens_user_idx" ON "notification_unsubscribe_tokens" USING btree ("user_id","created_at" DESC NULLS LAST);--> statement-breakpoint
INSERT INTO "notification_unsubscribe_tokens" ("id", "user_id", "token_hash", "created_at")
SELECT "user_id", "user_id", "unsubscribe_token_hash", now()
FROM "notification_settings"
WHERE "unsubscribe_token_hash" IS NOT NULL
ON CONFLICT ("token_hash") DO NOTHING;