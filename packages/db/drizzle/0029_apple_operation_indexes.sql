CREATE INDEX "apple_operations_user_idx" ON "apple_operations" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "apple_operations_email_idx" ON "apple_operations" USING btree ("email");--> statement-breakpoint
CREATE INDEX "apple_operations_expiry_idx" ON "apple_operations" USING btree ("expires_at");