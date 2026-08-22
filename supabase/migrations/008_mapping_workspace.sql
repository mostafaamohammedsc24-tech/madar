-- Floor Plan / Property Mapping Engineer workspace.
-- Separate from information, photography, and publishing employees.
-- Engineer cannot publish the public listing.

CREATE TABLE IF NOT EXISTS mapping_staff (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id text NOT NULL UNIQUE,
  display_name text NOT NULL,
  role text NOT NULL DEFAULT 'floor_plan_engineer'
    CHECK (role IN ('floor_plan_engineer', 'mapping_supervisor')),
  secret_hash text NOT NULL,
  country_code text NOT NULL DEFAULT 'IQ',
  status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'suspended')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS mapping_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id uuid NOT NULL REFERENCES mapping_staff(id) ON DELETE CASCADE,
  session_token text NOT NULL UNIQUE,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_mapping_sessions_token ON mapping_sessions (session_token);

CREATE TABLE IF NOT EXISTS mapping_plan_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id text NOT NULL,
  request_id text NOT NULL,
  version integer NOT NULL,
  status text NOT NULL,
  source_path text,
  geometry jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_by_staff_id uuid REFERENCES mapping_staff(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (property_id, version)
);

CREATE TABLE IF NOT EXISTS mapping_audit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id text NOT NULL,
  request_id text NOT NULL,
  employee_id text NOT NULL,
  action text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_mapping_audit_property ON mapping_audit_events (property_id);

CREATE OR REPLACE FUNCTION mapping_login(p_employee_id text, p_secret_code text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_staff mapping_staff%ROWTYPE;
  v_token text;
  v_expires timestamptz;
BEGIN
  SELECT * INTO v_staff
  FROM mapping_staff
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

  INSERT INTO mapping_sessions (staff_id, session_token, expires_at)
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
