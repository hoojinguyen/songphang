CREATE TABLE "push_devices" (
	"id" uuid PRIMARY KEY NOT NULL,
	"user_id" uuid NOT NULL,
	"session_id" uuid NOT NULL,
	"platform" text NOT NULL,
	"token" text NOT NULL,
	"environment" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"last_seen_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "push_devices_token_unique" UNIQUE("token"),
	CONSTRAINT "push_devices_platform_check" CHECK ("push_devices"."platform" in ('ios', 'android')),
	CONSTRAINT "push_devices_environment_check" CHECK ("push_devices"."environment" in ('sandbox', 'production')),
	CONSTRAINT "push_devices_token_length_check" CHECK (char_length("push_devices"."token") between 16 and 512)
);
--> statement-breakpoint
ALTER TABLE "users" ADD COLUMN "hide_push_content" boolean DEFAULT false NOT NULL;--> statement-breakpoint
ALTER TABLE "push_devices" ADD CONSTRAINT "push_devices_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "push_devices" ADD CONSTRAINT "push_devices_session_id_sessions_id_fk" FOREIGN KEY ("session_id") REFERENCES "public"."sessions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "push_devices_user_id_idx" ON "push_devices" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "push_devices_session_id_idx" ON "push_devices" USING btree ("session_id");