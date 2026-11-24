ALTER TABLE "sessions" ADD COLUMN "client" text DEFAULT 'web' NOT NULL;--> statement-breakpoint
ALTER TABLE "sessions" ADD COLUMN "device_name" text;--> statement-breakpoint
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_client_check" CHECK ("sessions"."client" in ('web', 'ios', 'android'));--> statement-breakpoint
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_device_name_length_check" CHECK ("sessions"."device_name" is null or char_length("sessions"."device_name") between 1 and 60);