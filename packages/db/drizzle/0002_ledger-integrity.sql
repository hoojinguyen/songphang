CREATE FUNCTION assert_transaction_integrity(checked_id uuid) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  expected_amount bigint;
  owning_group uuid;
  paid_total bigint;
  shared_total bigint;
  outside_members integer;
BEGIN
  SELECT amount, group_id INTO expected_amount, owning_group
  FROM transactions WHERE id = checked_id;
  IF NOT FOUND THEN
    RETURN; -- the transaction was removed in this same database transaction
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
END $$;
--> statement-breakpoint
CREATE FUNCTION check_transaction_row() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM assert_transaction_integrity(NEW.id);
  RETURN NULL;
END $$;
--> statement-breakpoint
CREATE FUNCTION check_transaction_line() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP <> 'INSERT' THEN
    PERFORM assert_transaction_integrity(OLD.transaction_id);
  END IF;
  IF TG_OP <> 'DELETE' THEN
    PERFORM assert_transaction_integrity(NEW.transaction_id);
  END IF;
  RETURN NULL;
END $$;
--> statement-breakpoint
CREATE CONSTRAINT TRIGGER transactions_integrity
AFTER INSERT OR UPDATE OF amount, group_id ON transactions
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_transaction_row();
--> statement-breakpoint
CREATE CONSTRAINT TRIGGER transaction_payers_integrity
AFTER INSERT OR UPDATE OR DELETE ON transaction_payers
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_transaction_line();
--> statement-breakpoint
CREATE CONSTRAINT TRIGGER transaction_shares_integrity
AFTER INSERT OR UPDATE OR DELETE ON transaction_shares
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_transaction_line();
