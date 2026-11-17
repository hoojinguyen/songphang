CREATE TABLE "member_payment_methods" (
	"id" uuid PRIMARY KEY NOT NULL,
	"member_id" uuid NOT NULL,
	"kind" text NOT NULL,
	"bank_bin" text,
	"account_number" text NOT NULL,
	"account_name" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "member_payment_methods_kind_unique" UNIQUE("member_id","kind"),
	CONSTRAINT "payment_kind_check" CHECK ("member_payment_methods"."kind" in ('bank','momo','zalopay')),
	CONSTRAINT "payment_bank_check" CHECK (("member_payment_methods"."kind" = 'bank' and "member_payment_methods"."bank_bin" is not null and "member_payment_methods"."bank_bin" ~ '^[0-9]{6}$' and "member_payment_methods"."account_name" is not null and char_length("member_payment_methods"."account_name") between 1 and 50 and "member_payment_methods"."account_number" ~ '^[A-Za-z0-9]{4,19}$') or ("member_payment_methods"."kind" <> 'bank' and "member_payment_methods"."bank_bin" is null and "member_payment_methods"."account_number" ~ '^0[0-9]{9}$'))
);
--> statement-breakpoint
ALTER TABLE "member_payment_methods" ADD CONSTRAINT "member_payment_methods_member_id_members_id_fk" FOREIGN KEY ("member_id") REFERENCES "public"."members"("id") ON DELETE cascade ON UPDATE no action;