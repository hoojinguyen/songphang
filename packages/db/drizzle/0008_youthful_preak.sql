ALTER TABLE "members" DROP CONSTRAINT "members_shape_check";--> statement-breakpoint
ALTER TABLE "members" DROP CONSTRAINT "members_color_check";--> statement-breakpoint
ALTER TABLE "members" ADD COLUMN "kind" text DEFAULT 'person' NOT NULL;--> statement-breakpoint
ALTER TABLE "members" ADD COLUMN "fund_holder_member_id" uuid;--> statement-breakpoint
ALTER TABLE "members" ADD CONSTRAINT "members_fund_holder_member_id_members_id_fk" FOREIGN KEY ("fund_holder_member_id") REFERENCES "public"."members"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "members_group_fund_unique" ON "members" USING btree ("group_id") WHERE "members"."kind" = 'fund';--> statement-breakpoint
ALTER TABLE "members" ADD CONSTRAINT "members_kind_check" CHECK ("members"."kind" in ('person', 'fund'));--> statement-breakpoint
ALTER TABLE "members" ADD CONSTRAINT "members_fund_holder_kind_check" CHECK ("members"."kind" = 'fund' or "members"."fund_holder_member_id" is null);--> statement-breakpoint
ALTER TABLE "members" ADD CONSTRAINT "members_shape_check" CHECK ("members"."shape" in ('circle', 'diamond', 'squircle', 'leaf', 'fund'));--> statement-breakpoint
ALTER TABLE "members" ADD CONSTRAINT "members_color_check" CHECK ("members"."color" in ('mint', 'sky', 'coral', 'lilac', 'sun'));
--> statement-breakpoint
CREATE OR REPLACE FUNCTION assert_transaction_integrity(checked_id uuid) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  expected_amount bigint;
  owning_group uuid;
  tx_type text;
  paid_total bigint;
  shared_total bigint;
  outside_members integer;
  fund_shares integer;
BEGIN
  SELECT amount, group_id, type INTO expected_amount, owning_group, tx_type
  FROM transactions WHERE id = checked_id;
  IF NOT FOUND THEN
    RETURN;
  END IF;
  SELECT COALESCE(SUM(amount), 0)::bigint INTO paid_total
  FROM transaction_payers WHERE transaction_id = checked_id;
  SELECT COALESCE(SUM(amount), 0)::bigint INTO shared_total
  FROM transaction_shares WHERE transaction_id = checked_id;
  IF paid_total <> expected_amount THEN
    RAISE EXCEPTION 'transaction payers total differs from amount'
      USING ERRCODE = 'check_violation';
  END IF;
  IF shared_total <> expected_amount THEN
    RAISE EXCEPTION 'transaction shares total differs from amount'
      USING ERRCODE = 'check_violation';
  END IF;
  SELECT COUNT(*) INTO outside_members
  FROM (
    SELECT member_id FROM transaction_payers WHERE transaction_id = checked_id
    UNION ALL
    SELECT member_id FROM transaction_shares WHERE transaction_id = checked_id
  ) used
  JOIN members ON members.id = used.member_id
  WHERE members.group_id <> owning_group;
  IF outside_members > 0 THEN
    RAISE EXCEPTION 'transaction references a member of another group'
      USING ERRCODE = 'check_violation';
  END IF;
  IF tx_type IN ('expense', 'income') THEN
    SELECT COUNT(*) INTO fund_shares
    FROM transaction_shares s
    JOIN members m ON m.id = s.member_id
    WHERE s.transaction_id = checked_id
      AND m.kind = 'fund';
    IF fund_shares > 0 THEN
      RAISE EXCEPTION 'fund member cannot appear in transaction shares'
        USING ERRCODE = 'check_violation';
    END IF;
  END IF;
END $$;--> statement-breakpoint
DROP TRIGGER transactions_integrity ON transactions;--> statement-breakpoint
CREATE CONSTRAINT TRIGGER transactions_integrity
AFTER INSERT OR UPDATE OF amount, group_id, type ON transactions
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_transaction_row();--> statement-breakpoint
CREATE FUNCTION check_group_user_member_is_person() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.member_id IS NOT NULL AND EXISTS (
    SELECT 1 FROM members WHERE id = NEW.member_id AND kind = 'fund'
  ) THEN
    RAISE EXCEPTION 'group user cannot link to a fund member'
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END $$;--> statement-breakpoint
CREATE TRIGGER group_users_person_member
BEFORE INSERT OR UPDATE OF member_id ON group_users
FOR EACH ROW EXECUTE FUNCTION check_group_user_member_is_person();
