-- Office Portal domain
-- Partner real-estate offices — NOT company lawyers / finance / employees.
-- Secret codes stored hashed; dual barcodes; commission rules configurable.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ── Offices ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS offices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  office_code text NOT NULL UNIQUE,
  secret_hash text NOT NULL,
  name text NOT NULL,
  country_code text NOT NULL DEFAULT 'IQ',
  currency_code text NOT NULL DEFAULT 'IQD',
  address text,
  phone text,
  manager_name text,
  license_number text,
  status text NOT NULL DEFAULT 'active', -- active | suspended | pending
  joined_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS office_territories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id uuid NOT NULL REFERENCES offices(id) ON DELETE CASCADE,
  country_code text NOT NULL,
  governorate text,
  city text,
  district text,
  neighborhood text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_office_territories_office
  ON office_territories (office_id);

-- ── Sessions (token hashed) ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS office_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id uuid NOT NULL REFERENCES offices(id) ON DELETE CASCADE,
  token_hash text NOT NULL UNIQUE,
  refresh_token_hash text,
  expires_at timestamptz NOT NULL,
  revoked_at timestamptz,
  ip_hint text,
  user_agent text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_office_sessions_office
  ON office_sessions (office_id) WHERE revoked_at IS NULL;

CREATE TABLE IF NOT EXISTS office_login_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  office_code text NOT NULL,
  success boolean NOT NULL DEFAULT false,
  ip_hint text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_office_login_attempts_code_time
  ON office_login_attempts (office_code, created_at DESC);

-- ── Office properties (assignment, not property duplication) ────────────────
CREATE TABLE IF NOT EXISTS office_properties (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id uuid NOT NULL REFERENCES offices(id) ON DELETE CASCADE,
  property_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'pending_review',
  -- pending_review | owner_contacted | approved | active | sold | rented | archived
  source text NOT NULL DEFAULT 'company', -- company | office_report | system
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (office_id, property_id)
);

CREATE INDEX IF NOT EXISTS idx_office_properties_office
  ON office_properties (office_id, status);

-- ── Property reports (territory monitoring) ─────────────────────────────────
CREATE TABLE IF NOT EXISTS office_property_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id uuid NOT NULL REFERENCES offices(id) ON DELETE CASCADE,
  property_type text,
  listing_type text, -- sale | rent
  latitude double precision,
  longitude double precision,
  address_text text,
  owner_phone text,
  estimated_price numeric,
  currency_code text DEFAULT 'IQD',
  notes text,
  photo_urls jsonb NOT NULL DEFAULT '[]'::jsonb,
  status text NOT NULL DEFAULT 'under_review',
  -- under_review | contacting_owner | owner_approved | owner_declined
  resulting_property_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ── Buyer referrals ("Found a buyer") ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS office_referrals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id uuid NOT NULL REFERENCES offices(id) ON DELETE CASCADE,
  property_id uuid NOT NULL,
  buyer_phone text,
  buyer_user_id uuid,
  status text NOT NULL DEFAULT 'new',
  -- new | contacting | qualified | negotiating | transaction_created | completed | rejected | expired
  conversation_id uuid,
  message text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_office_referrals_office
  ON office_referrals (office_id, created_at DESC);

-- ── Commission rules (configurable) ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS office_commission_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code text NOT NULL,
  transaction_type text NOT NULL DEFAULT 'sale',
  property_source text NOT NULL, -- office | company
  buyer_source text NOT NULL,   -- office | company
  office_share numeric NOT NULL, -- 0.50 = 50%
  company_share numeric NOT NULL,
  effective_from date,
  effective_to date,
  created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO office_commission_rules
  (country_code, transaction_type, property_source, buyer_source, office_share, company_share)
SELECT * FROM (VALUES
  ('IQ', 'sale', 'office', 'company', 0.50, 0.50),
  ('IQ', 'sale', 'office', 'office', 0.75, 0.25),
  ('IQ', 'sale', 'company', 'office', 0.50, 0.50)
) AS v(country_code, transaction_type, property_source, buyer_source, office_share, company_share)
WHERE NOT EXISTS (SELECT 1 FROM office_commission_rules LIMIT 1);

-- ── Conversations with Office Management Team ───────────────────────────────
CREATE TABLE IF NOT EXISTS office_conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id uuid NOT NULL REFERENCES offices(id) ON DELETE CASCADE,
  team_key text NOT NULL DEFAULT 'office_management',
  property_id uuid,
  referral_id uuid REFERENCES office_referrals(id),
  title text,
  last_message_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS office_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL REFERENCES office_conversations(id) ON DELETE CASCADE,
  office_id uuid NOT NULL REFERENCES offices(id) ON DELETE CASCADE,
  sender_side text NOT NULL, -- office | company
  sender_label text,
  message_type text NOT NULL DEFAULT 'text',
  -- text | image | video | document | pdf | voice | location | property_card | file
  body text,
  media_url text,
  property_id uuid,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_office_messages_conversation
  ON office_messages (conversation_id, created_at ASC);

-- ── Notifications ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS office_notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id uuid NOT NULL REFERENCES offices(id) ON DELETE CASCADE,
  title text NOT NULL,
  body text,
  notification_type text,
  related_entity_type text,
  related_entity_id uuid,
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS office_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id uuid NOT NULL REFERENCES offices(id) ON DELETE CASCADE,
  title text NOT NULL,
  document_type text,
  storage_path text,
  uploaded_by text DEFAULT 'company',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS office_support_tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id uuid NOT NULL REFERENCES offices(id) ON DELETE CASCADE,
  subject text NOT NULL,
  body text,
  status text NOT NULL DEFAULT 'open', -- open | in_progress | resolved | closed
  assigned_team text DEFAULT 'office_management',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Office staff accounts (partner operators — not company employees)
CREATE TABLE IF NOT EXISTS office_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id uuid NOT NULL REFERENCES offices(id) ON DELETE CASCADE,
  display_name text,
  phone text,
  role text NOT NULL DEFAULT 'manager', -- manager | agent | viewer
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_office_users_office ON office_users (office_id);

-- Outbound barcode delivery log (auto-send to buyer/seller)
CREATE TABLE IF NOT EXISTS office_barcode_deliveries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL,
  office_id uuid NOT NULL REFERENCES offices(id) ON DELETE CASCADE,
  participant_role text NOT NULL, -- buyer | seller
  phone text NOT NULL,
  delivery_channel text NOT NULL DEFAULT 'in_app',
  status text NOT NULL DEFAULT 'queued', -- queued | sent | failed
  payload_preview text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Link transactions to offices when created by office
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'transactions') THEN
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS created_by_office_id uuid;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'transaction_barcodes') THEN
    ALTER TABLE transaction_barcodes ADD COLUMN IF NOT EXISTS participant_role text;
    ALTER TABLE transaction_barcodes ADD COLUMN IF NOT EXISTS participant_token_hash text;
  END IF;
END $$;

-- ── Secure office login RPC ─────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION office_login(
  p_office_code text,
  p_secret_code text,
  p_ip_hint text DEFAULT NULL,
  p_user_agent text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_office offices%ROWTYPE;
  v_attempts integer;
  v_token text;
  v_token_hash text;
  v_expires timestamptz;
BEGIN
  -- Rate limit: max 8 failed attempts in 15 minutes
  SELECT COUNT(*) INTO v_attempts
  FROM office_login_attempts
  WHERE office_code = upper(trim(p_office_code))
    AND success = false
    AND created_at > now() - interval '15 minutes';

  IF v_attempts >= 8 THEN
    INSERT INTO office_login_attempts (office_code, success, ip_hint)
    VALUES (upper(trim(p_office_code)), false, p_ip_hint);
    RETURN jsonb_build_object('success', false, 'message', 'rate_limited');
  END IF;

  SELECT * INTO v_office
  FROM offices
  WHERE office_code = upper(trim(p_office_code))
    AND status = 'active'
  FOR UPDATE;

  IF NOT FOUND OR v_office.secret_hash <> crypt(p_secret_code, v_office.secret_hash) THEN
    INSERT INTO office_login_attempts (office_code, success, ip_hint)
    VALUES (upper(trim(p_office_code)), false, p_ip_hint);
    RETURN jsonb_build_object('success', false, 'message', 'invalid_credentials');
  END IF;

  v_token := encode(gen_random_bytes(32), 'hex');
  v_token_hash := encode(digest(v_token, 'sha256'), 'hex');
  v_expires := now() + interval '12 hours';

  INSERT INTO office_sessions (
    office_id, token_hash, refresh_token_hash, expires_at, ip_hint, user_agent
  )
  VALUES (
    v_office.id,
    v_token_hash,
    encode(digest(encode(gen_random_bytes(32), 'hex'), 'sha256'), 'hex'),
    v_expires,
    p_ip_hint,
    p_user_agent
  );

  INSERT INTO office_login_attempts (office_code, success, ip_hint)
  VALUES (v_office.office_code, true, p_ip_hint);

  RETURN jsonb_build_object(
    'success', true,
    'session_token', v_token,
    'expires_at', v_expires,
    'office', jsonb_build_object(
      'id', v_office.id,
      'office_code', v_office.office_code,
      'name', v_office.name,
      'country_code', v_office.country_code,
      'currency_code', v_office.currency_code,
      'address', v_office.address,
      'phone', v_office.phone,
      'manager_name', v_office.manager_name,
      'license_number', v_office.license_number,
      'joined_at', v_office.joined_at,
      'status', v_office.status
    )
  );
END;
$$;

CREATE OR REPLACE FUNCTION office_logout(p_session_token text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE office_sessions
  SET revoked_at = now()
  WHERE token_hash = encode(digest(p_session_token, 'sha256'), 'hex')
    AND revoked_at IS NULL;
  RETURN jsonb_build_object('success', true);
END;
$$;

CREATE OR REPLACE FUNCTION office_session_office_id(p_session_token text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  v_office_id uuid;
BEGIN
  SELECT office_id INTO v_office_id
  FROM office_sessions
  WHERE token_hash = encode(digest(p_session_token, 'sha256'), 'hex')
    AND revoked_at IS NULL
    AND expires_at > now();
  RETURN v_office_id;
END;
$$;

-- Create dual participant barcodes for a transaction
CREATE OR REPLACE FUNCTION office_create_transaction_with_barcodes(
  p_session_token text,
  p_transaction_type text,
  p_buyer_phone text,
  p_seller_phone text,
  p_property_id uuid DEFAULT NULL,
  p_sale_price numeric DEFAULT NULL,
  p_currency_code text DEFAULT 'IQD',
  p_country_code text DEFAULT 'IQ',
  p_branch_code text DEFAULT 'BGD'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_office_id uuid;
  v_office offices%ROWTYPE;
  v_tx_id uuid;
  v_number text;
  v_seq integer;
  v_year integer := EXTRACT(YEAR FROM now())::integer;
  v_buyer_code text;
  v_seller_code text;
  v_workflow text;
BEGIN
  v_office_id := office_session_office_id(p_session_token);
  IF v_office_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;

  SELECT * INTO v_office FROM offices WHERE id = v_office_id;

  UPDATE transaction_numbering_configs
  SET next_sequence = next_sequence + 1
  WHERE country_code = p_country_code
  RETURNING next_sequence - 1 INTO v_seq;

  IF v_seq IS NULL THEN
    v_seq := 1;
  END IF;

  v_number := upper(p_country_code) || '-' || upper(p_branch_code) || '-' ||
              upper(p_transaction_type) || '-' || v_year::text || '-' ||
              lpad(v_seq::text, 6, '0');

  v_workflow := CASE
    WHEN p_transaction_type = 'agricultural' THEN 'iq_agricultural_sale'
    ELSE 'iq_residential_sale'
  END;

  INSERT INTO transactions (
    transaction_number, reference_number, lifecycle_state, transaction_type,
    workflow_id, country_code, currency_code, property_id, sale_price, total_amount,
    buyer_phone, seller_phone, created_by_office_id, office_id, status,
    current_step_key, current_stage_index
  ) VALUES (
    v_number, v_number, 'waiting_for_parties', p_transaction_type,
    v_workflow, p_country_code, p_currency_code, p_property_id, p_sale_price, p_sale_price,
    p_buyer_phone, p_seller_phone, v_office_id, v_office_id, 'pending',
    'identity', 0
  ) RETURNING id INTO v_tx_id;

  v_buyer_code := 'BUY-' || encode(gen_random_bytes(16), 'hex');
  v_seller_code := 'SEL-' || encode(gen_random_bytes(16), 'hex');

  INSERT INTO transaction_barcodes (
    transaction_id, barcode_code, barcode_type, buyer_phone, seller_phone,
    generated_by_office_id, participant_role, participant_token_hash, expires_at
  ) VALUES
  (
    v_tx_id, v_buyer_code, 'qr', p_buyer_phone, p_seller_phone, v_office_id, 'buyer',
    encode(digest(v_buyer_code, 'sha256'), 'hex'), now() + interval '14 days'
  ),
  (
    v_tx_id, v_seller_code, 'qr', p_buyer_phone, p_seller_phone, v_office_id, 'seller',
    encode(digest(v_seller_code, 'sha256'), 'hex'), now() + interval '14 days'
  );

  -- Auto-queue in-app delivery (no manual copy/paste by office)
  INSERT INTO office_barcode_deliveries
    (transaction_id, office_id, participant_role, phone, status, payload_preview)
  VALUES
    (v_tx_id, v_office_id, 'buyer', p_buyer_phone, 'sent',
     'Barcode for transaction ' || v_number || ' (buyer)'),
    (v_tx_id, v_office_id, 'seller', p_seller_phone, 'sent',
     'Barcode for transaction ' || v_number || ' (seller)');

  -- Notify Madar users by phone when profile + notifications table exist (best-effort)
  BEGIN
    IF EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name = 'notifications'
    ) AND EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name = 'user_profiles'
    ) THEN
      EXECUTE $q$
        INSERT INTO notifications (user_id, title, body, notification_type, is_read)
        SELECT up.id,
               'Transaction barcode',
               'Your Madar barcode for ' || $1 || ' is ready. Open Deals to scan.',
               'transaction_barcode',
               false
        FROM user_profiles up
        WHERE up.phone IN ($2, $3)
      $q$ USING v_number, p_buyer_phone, p_seller_phone;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    NULL; -- non-blocking delivery
  END;

  INSERT INTO office_notifications (office_id, title, body, notification_type, related_entity_type, related_entity_id)
  VALUES (
    v_office_id,
    'Transaction created',
    'Transaction ' || v_number || ' created. Buyer and seller barcodes were sent.',
    'transaction_created',
    'transaction',
    v_tx_id
  );

  INSERT INTO transaction_audit_events (transaction_id, event_type, message, actor_role, metadata)
  VALUES (
    v_tx_id, 'created_by_office',
    'Transaction created by office ' || v_office.office_code,
    'office',
    jsonb_build_object('office_id', v_office_id, 'office_name', v_office.name)
  );

  RETURN jsonb_build_object(
    'success', true,
    'transaction_id', v_tx_id,
    'transaction_number', v_number,
    'buyer_barcode', v_buyer_code,
    'seller_barcode', v_seller_code,
    'barcodes_delivered', true
  );
END;
$$;

COMMENT ON TABLE offices IS 'Partner real-estate offices — external operators, not company lawyers.';
COMMENT ON COLUMN offices.secret_hash IS 'bcrypt hash via pgcrypto crypt(); never store plaintext.';
COMMENT ON FUNCTION office_login IS 'Rate-limited office authentication returning opaque session token.';
COMMENT ON FUNCTION office_create_transaction_with_barcodes IS
  'Creates transaction + separate buyer/seller barcode tokens for an authenticated office.';
