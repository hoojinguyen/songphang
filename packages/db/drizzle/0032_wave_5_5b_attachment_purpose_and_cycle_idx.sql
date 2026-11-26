ALTER TABLE "attachments" ADD COLUMN "purpose" text DEFAULT 'expense' NOT NULL;--> statement-breakpoint
CREATE INDEX "transactions_cycle_id_idx" ON "transactions" USING btree ("cycle_id") WHERE "transactions"."cycle_id" is not null;--> statement-breakpoint
ALTER TABLE "attachments" ADD CONSTRAINT "attachments_purpose_check" CHECK ("attachments"."purpose" in ('expense', 'transfer_proof'));