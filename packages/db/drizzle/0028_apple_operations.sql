CREATE TABLE "apple_operations" (
	"key" text PRIMARY KEY NOT NULL,
	"owner" uuid NOT NULL,
	"user_id" uuid,
	"email" text,
	"expires_at" timestamp with time zone NOT NULL
);
