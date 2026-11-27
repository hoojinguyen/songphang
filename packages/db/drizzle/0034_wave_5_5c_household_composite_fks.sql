ALTER TABLE "members" ADD CONSTRAINT "members_group_id_id_unique" UNIQUE("group_id","id");--> statement-breakpoint
ALTER TABLE "households" ADD CONSTRAINT "households_group_id_id_unique" UNIQUE("group_id","id");--> statement-breakpoint
ALTER TABLE "households" ADD CONSTRAINT "households_group_rep_fk" FOREIGN KEY ("group_id","representative_member_id") REFERENCES "public"."members"("group_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "members" ADD CONSTRAINT "members_group_household_fk" FOREIGN KEY ("group_id","household_id") REFERENCES "public"."households"("group_id","id") ON DELETE set null ("household_id") ON UPDATE no action;
