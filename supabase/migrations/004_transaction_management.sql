-- Transaction Management System (Deal Lifecycle)
-- Company Lawyer ≠ traditional real-estate agent.
-- Backend enforces dual-party barcode gate + lifecycle transitions.
-- Financial rates are configurable (no hardcoded 1% / 300k in app logic).

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ── Numbering config per country ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transaction_numbering_configs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code text NOT NULL UNIQUE,
  prefix text NOT NULL,
  include_branch boolean NOT NULL DEFAULT true,
  include_type boolean NOT NULL DEFAULT true,
  include_year boolean NOT NULL DEFAULT true,
  sequence_padding integer NOT NULL DEFAULT 6,
  next_sequence integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO transaction_numbering_configs (country_code, prefix)
VALUES ('IQ', 'IQ')
ON CONFLICT (country_code) DO NOTHING;

-- ── Workflow definitions ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transaction_workflows (
  id text PRIMARY KEY,
  country_code text NOT NULL,
  transaction_type text NOT NULL,
  name text NOT NULL,
  steps jsonb NOT NULL DEFAULT '[]'::jsonb,
  skip_deed boolean NOT NULL DEFAULT false,
  release_conditions jsonb NOT NULL DEFAULT '[]'::jsonb,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO transaction_workflows (id, country_code, transaction_type, name, steps, skip_deed, release_conditions)
VALUES
(
  'iq_residential_sale',
  'IQ',
  'sale',
  'Iraq Residential Sale',
  '[
    {"key":"identity","titleKey":"stepIdentity","order":1},
    {"key":"documents","titleKey":"stepDocuments","order":2},
    {"key":"contract","titleKey":"stepContract","order":3},
    {"key":"escrow","titleKey":"stepEscrow","order":4},
    {"key":"deed","titleKey":"stepDeed","order":5},
    {"key":"settlement","titleKey":"stepSettlement","order":6}
  ]'::jsonb,
  false,
  '["deed_verified","buyer_proof_uploaded","lawyer_verified"]'::jsonb
),
(
  'iq_agricultural_sale',
  'IQ',
  'agricultural',
  'Iraq Agricultural Sale',
  '[
    {"key":"identity","titleKey":"stepIdentity","order":1},
    {"key":"documents","titleKey":"stepDocuments","order":2},
    {"key":"contract","titleKey":"stepContract","order":3},
    {"key":"escrow","titleKey":"stepEscrow","order":4},
    {"key":"agricultural_transfer","titleKey":"stepAgriculturalTransfer","order":5},
    {"key":"settlement","titleKey":"stepSettlement","order":6}
  ]'::jsonb,
  true,
  '["buyer_moved_confirmed","buyer_approved","lawyer_verified"]'::jsonb
)
ON CONFLICT (id) DO NOTHING;

-- ── Commission / tax / service fee rules (configurable) ─────────────────────
CREATE TABLE IF NOT EXISTS commission_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code text NOT NULL,
  transaction_type text NOT NULL,
  property_type text,
  buyer_rate numeric NOT NULL DEFAULT 0.01,
  seller_rate numeric NOT NULL DEFAULT 0.01,
  effective_from date,
  effective_to date,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS service_fee_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code text NOT NULL,
  transaction_type text NOT NULL,
  buyer_fixed_amount numeric NOT NULL DEFAULT 0,
  seller_fixed_amount numeric NOT NULL DEFAULT 0,
  currency_code text NOT NULL DEFAULT 'IQD',
  effective_from date,
  effective_to date,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS tax_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code text NOT NULL,
  transaction_type text NOT NULL,
  property_type text,
  party_type text,
  rate numeric,
  fixed_amount numeric,
  currency_code text DEFAULT 'IQD',
  effective_from date,
  effective_to date,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Seed defaults for IQ sale (editable by Finance — not app hardcodes)
INSERT INTO commission_rules (country_code, transaction_type, buyer_rate, seller_rate)
SELECT 'IQ', 'sale', 0.01, 0.01
WHERE NOT EXISTS (
  SELECT 1 FROM commission_rules WHERE country_code = 'IQ' AND transaction_type = 'sale'
);

INSERT INTO service_fee_rules (country_code, transaction_type, buyer_fixed_amount, seller_fixed_amount, currency_code)
SELECT 'IQ', 'sale', 300000, 300000, 'IQD'
WHERE NOT EXISTS (
  SELECT 1 FROM service_fee_rules WHERE country_code = 'IQ' AND transaction_type = 'sale'
);

-- ── Escrow accounts (bank not hard-coded in domain code) ────────────────────
CREATE TABLE IF NOT EXISTS escrow_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code text NOT NULL,
  bank_name text NOT NULL,
  currency_code text NOT NULL,
  account_label text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO escrow_accounts (country_code, bank_name, currency_code, account_label)
SELECT 'IQ', 'Masraf Baghdad', 'IQD', 'Madar Company Escrow'
WHERE NOT EXISTS (
  SELECT 1 FROM escrow_accounts WHERE country_code = 'IQ' AND status = 'active'
);

-- ── Core transactions ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_number text NOT NULL UNIQUE,
  reference_number text,
  lifecycle_state text NOT NULL DEFAULT 'created',
  resume_state text,
  transaction_type text NOT NULL DEFAULT 'sale',
  workflow_id text REFERENCES transaction_workflows(id),
  country_code text NOT NULL DEFAULT 'IQ',
  currency_code text NOT NULL DEFAULT 'IQD',
  property_id uuid,
  property_address_snapshot text,
  sale_price numeric,
  total_amount numeric,
  buyer_user_id uuid,
  seller_user_id uuid,
  buyer_phone text,
  seller_phone text,
  buyer_name text,
  seller_name text,
  lawyer_user_id uuid,
  office_id uuid,
  buyer_barcode_uploaded boolean NOT NULL DEFAULT false,
  seller_barcode_uploaded boolean NOT NULL DEFAULT false,
  buyer_identity_verified boolean NOT NULL DEFAULT false,
  seller_identity_verified boolean NOT NULL DEFAULT false,
  buyer_signed_contract boolean NOT NULL DEFAULT false,
  seller_signed_contract boolean NOT NULL DEFAULT false,
  current_step_key text,
  current_stage_index integer DEFAULT 0,
  status text,
  escrow_account_id uuid REFERENCES escrow_accounts(id),
  required_escrow_amount numeric,
  deposited_escrow_amount numeric,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_transactions_buyer ON transactions (buyer_user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_seller ON transactions (seller_user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_state ON transactions (lifecycle_state);
CREATE INDEX IF NOT EXISTS idx_transactions_number ON transactions (transaction_number);

-- Compat columns if table already existed without TMS fields
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'transactions') THEN
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS transaction_number text;
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS lifecycle_state text DEFAULT 'created';
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS resume_state text;
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS workflow_id text;
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS sale_price numeric;
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS buyer_phone text;
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS seller_phone text;
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS lawyer_user_id uuid;
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS buyer_barcode_uploaded boolean DEFAULT false;
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS seller_barcode_uploaded boolean DEFAULT false;
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS buyer_identity_verified boolean DEFAULT false;
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS seller_identity_verified boolean DEFAULT false;
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS buyer_signed_contract boolean DEFAULT false;
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS seller_signed_contract boolean DEFAULT false;
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS current_step_key text;
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS escrow_account_id uuid;
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS required_escrow_amount numeric;
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS deposited_escrow_amount numeric;
  END IF;
END $$;

-- Backfill transaction_number from reference_number when missing
UPDATE transactions
SET transaction_number = COALESCE(transaction_number, reference_number, id::text)
WHERE transaction_number IS NULL;

-- ── Dual-party barcodes ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transaction_barcodes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  barcode_code text NOT NULL UNIQUE,
  barcode_type text NOT NULL DEFAULT 'qr',
  buyer_phone text,
  seller_phone text,
  generated_by_lawyer_id uuid,
  generated_by_office_id uuid,
  buyer_redeemed_at timestamptz,
  seller_redeemed_at timestamptz,
  buyer_redeemed_by_user_id uuid,
  seller_redeemed_by_user_id uuid,
  -- legacy single redeem (compat)
  redeemed_at timestamptz,
  redeemed_by_user_id uuid,
  expires_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'transaction_barcodes') THEN
    ALTER TABLE transaction_barcodes ADD COLUMN IF NOT EXISTS buyer_redeemed_at timestamptz;
    ALTER TABLE transaction_barcodes ADD COLUMN IF NOT EXISTS seller_redeemed_at timestamptz;
    ALTER TABLE transaction_barcodes ADD COLUMN IF NOT EXISTS buyer_redeemed_by_user_id uuid;
    ALTER TABLE transaction_barcodes ADD COLUMN IF NOT EXISTS seller_redeemed_by_user_id uuid;
    ALTER TABLE transaction_barcodes ADD COLUMN IF NOT EXISTS generated_by_lawyer_id uuid;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_transaction_barcodes_code ON transaction_barcodes (barcode_code);
CREATE INDEX IF NOT EXISTS idx_transaction_barcodes_tx ON transaction_barcodes (transaction_id);

-- ── Stages (compat + workflow steps) ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transaction_stages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  stage_index integer NOT NULL,
  step_key text,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  icon text,
  completed_at timestamptz,
  UNIQUE (transaction_id, stage_index)
);

-- ── Dynamic document requirements ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transaction_document_requirements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  required_for text NOT NULL DEFAULT 'both', -- buyer | seller | both
  status text NOT NULL DEFAULT 'required',
  deadline timestamptz,
  rejection_reason text,
  storage_path text,
  uploaded_by_user_id uuid,
  reviewed_by_user_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ── Contracts & signatures ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transaction_contracts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  version integer NOT NULL DEFAULT 1,
  pdf_path text,
  status text NOT NULL DEFAULT 'draft',
  created_by_lawyer_id uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS transaction_signatures (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  contract_id uuid REFERENCES transaction_contracts(id),
  party_side text NOT NULL, -- buyer | seller
  user_id uuid NOT NULL,
  signature_payload text,
  otp_verified_at timestamptz,
  face_verified_at timestamptz,
  signed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ── Financial lines + audit of overrides ────────────────────────────────────
CREATE TABLE IF NOT EXISTS transaction_fee_lines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  name text NOT NULL,
  amount numeric NOT NULL,
  currency_code text NOT NULL DEFAULT 'IQD',
  payer text, -- buyer | seller | company
  recipient text,
  reason text,
  status text NOT NULL DEFAULT 'proposed',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS transaction_financial_audit (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  field_name text NOT NULL,
  old_value text,
  new_value text,
  reason text,
  changed_by_user_id uuid,
  changed_by_role text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ── Legal team chat (transaction-specific) ──────────────────────────────────
CREATE TABLE IF NOT EXISTS transaction_legal_threads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL UNIQUE REFERENCES transactions(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS transaction_legal_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id uuid NOT NULL REFERENCES transaction_legal_threads(id) ON DELETE CASCADE,
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  sender_user_id uuid NOT NULL,
  sender_role text,
  body text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ── Immutable audit timeline ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transaction_audit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  event_type text NOT NULL,
  message text NOT NULL,
  actor_user_id uuid,
  actor_role text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_transaction_audit_tx
  ON transaction_audit_events (transaction_id, created_at ASC);

-- Prevent updates/deletes on audit (append-only)
CREATE OR REPLACE FUNCTION prevent_audit_mutation()
RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'transaction_audit_events is immutable';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_no_update ON transaction_audit_events;
CREATE TRIGGER trg_audit_no_update
  BEFORE UPDATE OR DELETE ON transaction_audit_events
  FOR EACH ROW EXECUTE FUNCTION prevent_audit_mutation();

-- ── External service notification abstraction ───────────────────────────────
CREATE TABLE IF NOT EXISTS external_service_notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  service_key text NOT NULL, -- furniture_beautification
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'pending', -- pending | sent | failed | skipped
  created_at timestamptz NOT NULL DEFAULT now(),
  sent_at timestamptz
);

-- Trigger only after contract executed (not at barcode creation)
CREATE OR REPLACE FUNCTION enqueue_furniture_lead_on_contract()
RETURNS trigger AS $$
BEGIN
  IF NEW.lifecycle_state = 'contract_executed'
     AND (OLD.lifecycle_state IS DISTINCT FROM 'contract_executed') THEN
    INSERT INTO external_service_notifications (transaction_id, service_key, payload, status)
    VALUES (
      NEW.id,
      'furniture_beautification',
      jsonb_build_object(
        'transaction_number', NEW.transaction_number,
        'buyer_phone', NEW.buyer_phone,
        'seller_phone', NEW.seller_phone,
        'buyer_user_id', NEW.buyer_user_id,
        'seller_user_id', NEW.seller_user_id,
        'property_id', NEW.property_id,
        'property_purchased', NEW.property_id,
        'buyer_existing_property', NULL,
        'property_sold', NEW.property_id,
        'seller_new_property', NULL
      ),
      'pending'
    );
    INSERT INTO transaction_audit_events (transaction_id, event_type, message, actor_role)
    VALUES (
      NEW.id,
      'external_service_queued',
      'Furniture/beautification service lead queued after contract execution',
      'system'
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_contract_external_service ON transactions;
CREATE TRIGGER trg_contract_external_service
  AFTER UPDATE OF lifecycle_state ON transactions
  FOR EACH ROW EXECUTE FUNCTION enqueue_furniture_lead_on_contract();

-- ── Dual-party barcode redeem function (backend source of truth) ────────────
CREATE OR REPLACE FUNCTION redeem_transaction_barcode(
  p_barcode_code text,
  p_user_id uuid,
  p_party_side text -- 'buyer' | 'seller'
)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_barcode transaction_barcodes%ROWTYPE;
  v_tx transactions%ROWTYPE;
BEGIN
  SELECT * INTO v_barcode
  FROM transaction_barcodes
  WHERE barcode_code = p_barcode_code
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'barcode_not_found');
  END IF;

  IF v_barcode.expires_at IS NOT NULL AND v_barcode.expires_at < now() THEN
    RETURN jsonb_build_object('success', false, 'message', 'barcode_expired');
  END IF;

  SELECT * INTO v_tx FROM transactions WHERE id = v_barcode.transaction_id FOR UPDATE;

  IF p_party_side = 'buyer' THEN
    UPDATE transaction_barcodes
    SET buyer_redeemed_at = COALESCE(buyer_redeemed_at, now()),
        buyer_redeemed_by_user_id = COALESCE(buyer_redeemed_by_user_id, p_user_id)
    WHERE id = v_barcode.id;
    UPDATE transactions
    SET buyer_barcode_uploaded = true,
        buyer_user_id = COALESCE(buyer_user_id, p_user_id),
        updated_at = now()
    WHERE id = v_tx.id;
  ELSIF p_party_side = 'seller' THEN
    UPDATE transaction_barcodes
    SET seller_redeemed_at = COALESCE(seller_redeemed_at, now()),
        seller_redeemed_by_user_id = COALESCE(seller_redeemed_by_user_id, p_user_id)
    WHERE id = v_barcode.id;
    UPDATE transactions
    SET seller_barcode_uploaded = true,
        seller_user_id = COALESCE(seller_user_id, p_user_id),
        updated_at = now()
    WHERE id = v_tx.id;
  ELSE
    RETURN jsonb_build_object('success', false, 'message', 'invalid_party_side');
  END IF;

  INSERT INTO transaction_audit_events (transaction_id, event_type, message, actor_user_id, actor_role)
  VALUES (
    v_tx.id,
    'barcode_uploaded',
    p_party_side || ' barcode uploaded',
    p_user_id,
    p_party_side
  );

  SELECT * INTO v_tx FROM transactions WHERE id = v_tx.id;

  IF v_tx.buyer_barcode_uploaded AND v_tx.seller_barcode_uploaded THEN
    IF v_tx.lifecycle_state IN ('created', 'waiting_for_parties') THEN
      UPDATE transactions
      SET lifecycle_state = 'parties_verified',
          current_step_key = 'identity',
          current_stage_index = 0,
          updated_at = now()
      WHERE id = v_tx.id;

      INSERT INTO transaction_audit_events (transaction_id, event_type, message, actor_role)
      VALUES (v_tx.id, 'parties_verified', 'Both parties barcode verified — transaction activated', 'system');
    END IF;

    RETURN jsonb_build_object(
      'success', true,
      'both_parties_verified', true,
      'transaction_id', v_tx.id,
      'transaction_number', v_tx.transaction_number,
      'lifecycle_state', 'parties_verified'
    );
  END IF;

  IF v_tx.lifecycle_state = 'created' THEN
    UPDATE transactions
    SET lifecycle_state = 'waiting_for_parties', updated_at = now()
    WHERE id = v_tx.id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'both_parties_verified', false,
    'waiting_for_other_party', true,
    'buyer_uploaded', v_tx.buyer_barcode_uploaded,
    'seller_uploaded', v_tx.seller_barcode_uploaded,
    'transaction_id', v_tx.id,
    'transaction_number', v_tx.transaction_number
  );
END;
$$;

COMMENT ON TABLE transactions IS
  'Digital real-estate deal lifecycle. Company Lawyer creates; both parties must redeem barcode before activation.';
COMMENT ON TABLE transaction_audit_events IS
  'Immutable audit timeline — no updates or deletes.';
COMMENT ON TABLE external_service_notifications IS
  'Abstraction for furniture/beautification company; queued only after contract_executed.';
COMMENT ON FUNCTION redeem_transaction_barcode IS
  'Dual-party barcode gate — both buyer and seller must upload before parties_verified.';
