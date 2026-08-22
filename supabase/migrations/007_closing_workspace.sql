-- Transaction & Closing Lawyer workspace (separate from Contract Lawyer).
-- This role cannot draft/edit contracts, confirm bank deposits, release escrow,
-- change commissions, manage staff/offices, or publish properties.

CREATE TABLE IF NOT EXISTS closing_staff (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id text NOT NULL UNIQUE,
  display_name text NOT NULL,
  role text NOT NULL DEFAULT 'transaction_closing_lawyer'
    CHECK (role IN ('transaction_closing_lawyer', 'closing_supervisor')),
  secret_hash text NOT NULL,
  country_code text NOT NULL DEFAULT 'IQ',
  status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'suspended')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS closing_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id uuid NOT NULL REFERENCES closing_staff(id) ON DELETE CASCADE,
  session_token text NOT NULL UNIQUE,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_closing_sessions_token ON closing_sessions (session_token);

CREATE TABLE IF NOT EXISTS closing_country_workflow (
  country_code text PRIMARY KEY,
  numbering_prefix text NOT NULL DEFAULT 'MAD',
  ownership_transfer_mode text NOT NULL DEFAULT 'physical'
    CHECK (ownership_transfer_mode IN ('physical', 'digital_ready')),
  skip_ownership_document_agricultural boolean NOT NULL DEFAULT false,
  escrow_release_conditions jsonb NOT NULL DEFAULT '[]'::jsonb,
  government_authorities jsonb NOT NULL DEFAULT '[]'::jsonb,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS closing_audit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_number text NOT NULL,
  staff_id uuid REFERENCES closing_staff(id),
  employee_id text NOT NULL,
  action text NOT NULL,
  result text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_closing_audit_tx ON closing_audit_events (transaction_number);

CREATE OR REPLACE FUNCTION closing_login(p_employee_id text, p_secret_code text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_staff closing_staff%ROWTYPE;
  v_token text;
  v_expires timestamptz;
BEGIN
  SELECT * INTO v_staff
  FROM closing_staff
  WHERE employee_id = upper(p_employee_id)
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

  INSERT INTO closing_sessions (staff_id, session_token, expires_at)
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

CREATE OR REPLACE FUNCTION closing_logout(p_session_token text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM closing_sessions WHERE session_token = p_session_token;
END;
$$;
