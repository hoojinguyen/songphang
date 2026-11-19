CREATE TABLE "ai_calls" (
	"id" uuid PRIMARY KEY NOT NULL,
	"user_id" uuid,
	"group_id" uuid,
	"purpose" text NOT NULL,
	"state" text DEFAULT 'reserved' NOT NULL,
	"model" text DEFAULT '' NOT NULL,
	"input_tokens" integer DEFAULT 0 NOT NULL,
	"output_tokens" integer DEFAULT 0 NOT NULL,
	"ok" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"started_at" timestamp with time zone,
	"finished_at" timestamp with time zone,
	CONSTRAINT "ai_calls_purpose_check" CHECK ("ai_calls"."purpose" in ('receipt', 'sentence')),
	CONSTRAINT "ai_calls_state_check" CHECK ("ai_calls"."state" in ('reserved', 'started', 'finished')),
	CONSTRAINT "ai_calls_input_tokens_check" CHECK ("ai_calls"."input_tokens" >= 0),
	CONSTRAINT "ai_calls_output_tokens_check" CHECK ("ai_calls"."output_tokens" >= 0)
);
--> statement-breakpoint
ALTER TABLE "ai_calls" ADD CONSTRAINT "ai_calls_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ai_calls" ADD CONSTRAINT "ai_calls_group_id_groups_id_fk" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "ai_calls_purpose_created_index" ON "ai_calls" USING btree ("purpose","created_at");--> statement-breakpoint
CREATE INDEX "ai_calls_user_purpose_created_index" ON "ai_calls" USING btree ("user_id","purpose","created_at");--> statement-breakpoint
CREATE INDEX "ai_calls_created_index" ON "ai_calls" USING btree ("created_at");