-- Contract Lawyer workspace (separate from office / finance / bank / public app).
-- Lawyer cannot confirm deposits, release escrow, change commissions, or transfer ownership.

CREATE TABLE IF NOT EXISTS legal_staff (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id text NOT NULL UNIQUE,
  display_name text NOT NULL,
  role text NOT NULL DEFAULT 'contract_lawyer'
    CHECK (role IN ('contract_lawyer', 'legal_supervisor')),
  secret_hash text NOT NULL,
  country_code text NOT NULL DEFAULT 'IQ',
  status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'suspended')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS legal_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id uuid NOT NULL REFERENCES legal_staff(id) ON DELETE CASCADE,
  session_token text NOT NULL UNIQUE,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_legal_sessions_token ON legal_sessions (session_token);

-- Document versions — never overwrite / never delete rejected files.
CREATE TABLE IF NOT EXISTS legal_document_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  requirement_id uuid NOT NULL REFERENCES transaction_document_requirements(id) ON DELETE CASCADE,
  version integer NOT NULL,
  status text NOT NULL,
  rejection_reason text,
  storage_path text,
  uploaded_by_user_id uuid,
  reviewed_by_staff_id uuid,
  notes_internal text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (requirement_id, version)
);

ALTER TABLE transaction_document_requirements
  ADD COLUMN IF NOT EXISTS is_optional boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS party_side text NOT NULL DEFAULT 'both',
  ADD COLUMN IF NOT EXISTS current_version integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS lawyer_notes text;

ALTER TABLE transaction_contracts
  ADD COLUMN IF NOT EXISTS contract_number text,
  ADD COLUMN IF NOT EXISTS body_json jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS change_notes text,
  ADD COLUMN IF NOT EXISTS modified_by_staff_id uuid,
  ADD COLUMN IF NOT EXISTS modified_at timestamptz,
  ADD COLUMN IF NOT EXISTS locked boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS sent_to_buyer_at timestamptz,
  ADD COLUMN IF NOT EXISTS sent_to_seller_at timestamptz,
  ADD COLUMN IF NOT EXISTS buyer_confirmation text NOT NULL DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS seller_confirmation text NOT NULL DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS buyer_rejected_reason text,
  ADD COLUMN IF NOT EXISTS seller_rejected_reason text,
  ADD COLUMN IF NOT EXISTS executed_at timestamptz,
  ADD COLUMN IF NOT EXISTS parent_version integer;

CREATE TABLE IF NOT EXISTS legal_clause_catalog (
  id text PRIMARY KEY,
  category text NOT NULL,
  title_ar text NOT NULL,
  title_en text NOT NULL,
  title_ku text NOT NULL,
  authorized boolean NOT NULL DEFAULT true,
  template_ref text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS legal_contract_amendments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  original_contract_id uuid NOT NULL REFERENCES transaction_contracts(id),
  reason text NOT NULL,
  affected_clause_id text,
  status text NOT NULL DEFAULT 'requested',
  new_contract_id uuid REFERENCES transaction_contracts(id),
  created_by_staff_id uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS legal_notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  visibility text NOT NULL CHECK (visibility IN ('internal', 'customer')),
  body text NOT NULL,
  created_by_staff_id uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS legal_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  channel text NOT NULL CHECK (channel IN ('buyer', 'seller', 'legal_team', 'closing', 'support', 'finance')),
  sender_staff_id uuid,
  sender_role text,
  body text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS user_face_captures (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  storage_path text NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now(),
  provider text NOT NULL DEFAULT 'pending_aws',
  match_status text NOT NULL DEFAULT 'captured'
    CHECK (match_status IN ('captured', 'pending_match', 'matched', 'mismatch', 'failed')),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_user_face_captures_user ON user_face_captures (user_id, captured_at DESC);

CREATE TABLE IF NOT EXISTS legal_notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id uuid REFERENCES legal_staff(id) ON DELETE CASCADE,
  transaction_id uuid REFERENCES transactions(id) ON DELETE CASCADE,
  kind text NOT NULL,
  title text NOT NULL,
  body text NOT NULL,
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_legal_notifications_staff
  ON legal_notifications (staff_id, created_at DESC);

-- Staff login RPC (hash compared in app layer via pgcrypto crypt)
CREATE OR REPLACE FUNCTION legal_login(
  p_employee_id text,
  p_secret_code text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_staff legal_staff%ROWTYPE;
  v_token text;
  v_expires timestamptz;
BEGIN
  SELECT * INTO v_staff
  FROM legal_staff
  WHERE upper(employee_id) = upper(trim(p_employee_id))
    AND status = 'active'
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'invalid_credentials');
  END IF;

  IF v_staff.secret_hash IS DISTINCT FROM crypt(p_secret_code, v_staff.secret_hash) THEN
    RETURN jsonb_build_object('success', false, 'message', 'invalid_credentials');
  END IF;

  v_token := encode(gen_random_bytes(32), 'hex');
  v_expires := now() + interval '12 hours';

  INSERT INTO legal_sessions (staff_id, session_token, expires_at)
  VALUES (v_staff.id, v_token, v_expires);

  RETURN jsonb_build_object(
    'success', true,
    'session_token', v_token,
    'expires_at', v_expires,
    'staff', jsonb_build_object(
      'id', v_staff.id,
      'employee_id', v_staff.employee_id,
      'display_name', v_staff.display_name,
      'role', v_staff.role,
      'country_code', v_staff.country_code
    )
  );
END;
$$;

CREATE OR REPLACE FUNCTION legal_logout(p_session_token text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM legal_sessions WHERE session_token = p_session_token;
END;
$$;
