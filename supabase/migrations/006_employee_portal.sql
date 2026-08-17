-- Employee Portal System — shared enterprise core + finance / bank / office-mgmt
-- Does NOT replace user or office portals. Secret codes hashed; RBAC enforced in RPCs.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ── Departments / Roles / Permissions ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS employee_departments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE, -- finance | bank | office_management | legal | publishing | ...
  name_en text NOT NULL,
  name_ar text,
  name_ku text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS employee_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  department_id uuid NOT NULL REFERENCES employee_departments(id) ON DELETE CASCADE,
  code text NOT NULL,
  name_en text NOT NULL,
  name_ar text,
  name_ku text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (department_id, code)
);

CREATE TABLE IF NOT EXISTS employee_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE, -- e.g. financial.edit
  description text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS employee_role_permissions (
  role_id uuid NOT NULL REFERENCES employee_roles(id) ON DELETE CASCADE,
  permission_id uuid NOT NULL REFERENCES employee_permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

-- ── Employees ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS employees (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_code text NOT NULL UNIQUE, -- EMP-IQ-000184 / FIN-IQ-00142
  secret_hash text NOT NULL,
  full_name text NOT NULL,
  profile_photo_url text,
  job_title text,
  department_id uuid NOT NULL REFERENCES employee_departments(id),
  role_id uuid NOT NULL REFERENCES employee_roles(id),
  country_code text NOT NULL DEFAULT 'IQ',
  branch_code text,
  region text,
  employment_status text NOT NULL DEFAULT 'active', -- active | suspended | terminated
  joining_date date,
  last_login_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_employees_department ON employees (department_id);
CREATE INDEX IF NOT EXISTS idx_employees_code ON employees (employee_code);

CREATE TABLE IF NOT EXISTS employee_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  token_hash text NOT NULL UNIQUE,
  refresh_token_hash text,
  expires_at timestamptz NOT NULL,
  revoked_at timestamptz,
  ip_hint text,
  user_agent text,
  device_label text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_employee_sessions_active
  ON employee_sessions (employee_id) WHERE revoked_at IS NULL;

CREATE TABLE IF NOT EXISTS employee_login_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_code text NOT NULL,
  success boolean NOT NULL DEFAULT false,
  ip_hint text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_employee_login_attempts_code_time
  ON employee_login_attempts (employee_code, created_at DESC);

CREATE TABLE IF NOT EXISTS employee_audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid REFERENCES employees(id),
  employee_code text,
  action text NOT NULL,
  entity_type text,
  entity_id text,
  old_value text,
  new_value text,
  reason text,
  ip_hint text,
  device_hint text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_employee_audit_created
  ON employee_audit_logs (created_at DESC);

CREATE TABLE IF NOT EXISTS employee_notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  title text NOT NULL,
  body text,
  notification_type text,
  related_entity_type text,
  related_entity_id uuid,
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS employee_internal_conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  department_code text,
  title text,
  created_by_employee_id uuid REFERENCES employees(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  last_message_at timestamptz
);

CREATE TABLE IF NOT EXISTS employee_internal_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL REFERENCES employee_internal_conversations(id) ON DELETE CASCADE,
  sender_employee_id uuid NOT NULL REFERENCES employees(id),
  message_type text NOT NULL DEFAULT 'text',
  body text,
  media_url text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ── Seed departments / permissions / roles ──────────────────────────────────
INSERT INTO employee_departments (code, name_en, name_ar, name_ku)
SELECT * FROM (VALUES
  ('finance', 'Finance', 'المالية', 'دارایی'),
  ('bank', 'Bank', 'المصرف', 'بانک'),
  ('office_management', 'Office Management', 'إدارة المكاتب', 'بەڕێوەبردنی ئۆفیس')
) AS v(code, name_en, name_ar, name_ku)
WHERE NOT EXISTS (SELECT 1 FROM employee_departments LIMIT 1);

INSERT INTO employee_permissions (code, description)
SELECT * FROM (VALUES
  ('transactions.view', 'View transactions'),
  ('transactions.create', 'Create transactions'),
  ('transactions.update', 'Update transactions'),
  ('financial.view', 'View financial data'),
  ('financial.edit', 'Edit financial amounts/fees'),
  ('financial.rules', 'Manage fee/commission rules'),
  ('financial.settlement', 'Prepare/approve settlements'),
  ('financial.reports', 'View/export finance reports'),
  ('bank.verify', 'Verify buyer identity'),
  ('bank.deposit.confirm', 'Confirm deposits'),
  ('bank.receipt.create', 'Create deposit receipts'),
  ('bank.partial_deposit', 'Allow partial deposits'),
  ('offices.view', 'View offices'),
  ('offices.create', 'Create offices'),
  ('offices.edit', 'Edit offices'),
  ('offices.suspend', 'Suspend/block offices'),
  ('offices.credentials.reset', 'Reset office secret'),
  ('properties.view', 'View properties/reports'),
  ('properties.assign', 'Assign properties to offices'),
  ('properties.publish.request', 'Request photography/publishing'),
  ('reports.view', 'View reports'),
  ('reports.export', 'Export reports'),
  ('messages.view', 'View internal messages'),
  ('messages.send', 'Send internal messages'),
  ('audit.view', 'View audit logs'),
  ('search.global', 'Use global employee search')
) AS v(code, description)
WHERE NOT EXISTS (SELECT 1 FROM employee_permissions LIMIT 1);

DO $$
DECLARE
  d_fin uuid; d_bank uuid; d_om uuid;
  r_fin uuid; r_bank uuid; r_om uuid;
BEGIN
  SELECT id INTO d_fin FROM employee_departments WHERE code = 'finance';
  SELECT id INTO d_bank FROM employee_departments WHERE code = 'bank';
  SELECT id INTO d_om FROM employee_departments WHERE code = 'office_management';

  IF NOT EXISTS (SELECT 1 FROM employee_roles WHERE code = 'finance_officer') THEN
    INSERT INTO employee_roles (department_id, code, name_en, name_ar)
    VALUES (d_fin, 'finance_officer', 'Finance Officer', 'موظف مالي')
    RETURNING id INTO r_fin;
    INSERT INTO employee_role_permissions (role_id, permission_id)
    SELECT r_fin, p.id FROM employee_permissions p
    WHERE p.code LIKE 'financial.%'
       OR p.code IN ('transactions.view','transactions.update','reports.view','reports.export','messages.view','messages.send','audit.view','search.global','offices.view');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM employee_roles WHERE code = 'bank_officer') THEN
    INSERT INTO employee_roles (department_id, code, name_en, name_ar)
    VALUES (d_bank, 'bank_officer', 'Bank Officer', 'موظف مصرف')
    RETURNING id INTO r_bank;
    INSERT INTO employee_role_permissions (role_id, permission_id)
    SELECT r_bank, p.id FROM employee_permissions p
    WHERE p.code LIKE 'bank.%'
       OR p.code IN ('transactions.view','messages.view','messages.send','audit.view','search.global');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM employee_roles WHERE code = 'office_manager') THEN
    INSERT INTO employee_roles (department_id, code, name_en, name_ar)
    VALUES (d_om, 'office_manager', 'Office Manager', 'مدير مكاتب')
    RETURNING id INTO r_om;
    INSERT INTO employee_role_permissions (role_id, permission_id)
    SELECT r_om, p.id FROM employee_permissions p
    WHERE p.code LIKE 'offices.%'
       OR p.code LIKE 'properties.%'
       OR p.code IN ('transactions.view','reports.view','messages.view','messages.send','audit.view','search.global');
  END IF;
END $$;

-- ── Financial status + deposits / settlements / payment requests ────────────
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'transactions') THEN
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS financial_status text DEFAULT 'awaiting_calculation';
    -- awaiting_calculation | amount_determined | awaiting_deposit | partially_deposited
    -- | fully_deposited | deposit_confirmed | awaiting_settlement | ready_for_release
    -- | released | completed | overdue | blocked | disputed
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS company_fees numeric;
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS tax_amount numeric;
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS office_commission_amount numeric;
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS bank_fees numeric;
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS seller_net_amount numeric;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS financial_fee_definitions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  fee_type text NOT NULL, -- percentage | fixed
  rate numeric,
  fixed_amount numeric,
  payer text, -- buyer | seller | company | office
  country_code text NOT NULL DEFAULT 'IQ',
  transaction_type text,
  property_type text,
  active_from date,
  active_until date,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS transaction_deposits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  required_amount numeric NOT NULL,
  actual_amount numeric,
  currency_code text NOT NULL DEFAULT 'IQD',
  reference_number text,
  deposit_date date,
  status text NOT NULL DEFAULT 'pending',
  -- pending | awaiting_otp | verified | confirmed | partial | rejected | failed
  confirmed_by_employee_id uuid REFERENCES employees(id),
  verified_buyer_at timestamptz,
  confirmed_at timestamptz,
  receipt_path text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS bank_buyer_otps (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  deposit_id uuid REFERENCES transaction_deposits(id) ON DELETE CASCADE,
  phone text NOT NULL,
  otp_hash text NOT NULL,
  attempts integer NOT NULL DEFAULT 0,
  max_attempts integer NOT NULL DEFAULT 5,
  expires_at timestamptz NOT NULL,
  verified_at timestamptz,
  requested_by_employee_id uuid REFERENCES employees(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS bank_deposit_receipts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  deposit_id uuid REFERENCES transaction_deposits(id),
  amount numeric NOT NULL,
  currency_code text NOT NULL DEFAULT 'IQD',
  bank_name text,
  reference_number text,
  deposit_date date,
  verified_by_employee_id uuid REFERENCES employees(id),
  buyer_phone text,
  property_snapshot text,
  storage_path text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS payment_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  amount numeric NOT NULL,
  currency_code text NOT NULL DEFAULT 'IQD',
  reason text,
  deadline date,
  status text NOT NULL DEFAULT 'sent',
  created_by_employee_id uuid REFERENCES employees(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS office_settlements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id uuid NOT NULL REFERENCES offices(id) ON DELETE CASCADE,
  period_start date,
  period_end date,
  office_commission numeric NOT NULL DEFAULT 0,
  company_share numeric NOT NULL DEFAULT 0,
  amount_due numeric NOT NULL DEFAULT 0,
  amount_paid numeric NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'prepared', -- prepared | approved | paid | confirmed
  settlement_date date,
  created_by_employee_id uuid REFERENCES employees(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS photography_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  temporary_property_id text NOT NULL,
  office_id uuid REFERENCES offices(id),
  report_id uuid,
  owner_phone text,
  location_text text,
  property_type text,
  notes text,
  priority text DEFAULT 'normal',
  status text NOT NULL DEFAULT 'waiting_for_photography',
  created_by_employee_id uuid REFERENCES employees(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Align office status values with management workflow
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'offices') THEN
    ALTER TABLE offices ADD COLUMN IF NOT EXISTS owner_full_name text;
    ALTER TABLE offices ADD COLUMN IF NOT EXISTS email text;
    ALTER TABLE offices ADD COLUMN IF NOT EXISTS city text;
    ALTER TABLE offices ADD COLUMN IF NOT EXISTS region text;
    ALTER TABLE offices ADD COLUMN IF NOT EXISTS latitude double precision;
    ALTER TABLE offices ADD COLUMN IF NOT EXISTS longitude double precision;
    ALTER TABLE offices ADD COLUMN IF NOT EXISTS office_type text;
    ALTER TABLE offices ADD COLUMN IF NOT EXISTS contract_info text;
    ALTER TABLE offices ADD COLUMN IF NOT EXISTS created_by_employee_id uuid;
  END IF;
END $$;

-- ── Helper: resolve employee from session ───────────────────────────────────
CREATE OR REPLACE FUNCTION employee_session_employee_id(p_session_token text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  v_id uuid;
BEGIN
  SELECT employee_id INTO v_id
  FROM employee_sessions
  WHERE token_hash = encode(digest(p_session_token, 'sha256'), 'hex')
    AND revoked_at IS NULL
    AND expires_at > now();
  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION employee_has_permission(
  p_employee_id uuid,
  p_permission_code text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  v_ok boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM employees e
    JOIN employee_role_permissions rp ON rp.role_id = e.role_id
    JOIN employee_permissions p ON p.id = rp.permission_id
    WHERE e.id = p_employee_id
      AND e.employment_status = 'active'
      AND p.code = p_permission_code
  ) INTO v_ok;
  RETURN COALESCE(v_ok, false);
END;
$$;

CREATE OR REPLACE FUNCTION employee_write_audit(
  p_employee_id uuid,
  p_action text,
  p_entity_type text DEFAULT NULL,
  p_entity_id text DEFAULT NULL,
  p_old_value text DEFAULT NULL,
  p_new_value text DEFAULT NULL,
  p_reason text DEFAULT NULL,
  p_ip_hint text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_code text;
BEGIN
  SELECT employee_code INTO v_code FROM employees WHERE id = p_employee_id;
  INSERT INTO employee_audit_logs (
    employee_id, employee_code, action, entity_type, entity_id,
    old_value, new_value, reason, ip_hint
  ) VALUES (
    p_employee_id, v_code, p_action, p_entity_type, p_entity_id,
    p_old_value, p_new_value, p_reason, p_ip_hint
  );
END;
$$;

-- ── Employee login ──────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION employee_login(
  p_employee_code text,
  p_secret_code text,
  p_ip_hint text DEFAULT NULL,
  p_user_agent text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_emp employees%ROWTYPE;
  v_attempts integer;
  v_token text;
  v_expires timestamptz;
  v_dept employee_departments%ROWTYPE;
  v_role employee_roles%ROWTYPE;
  v_perms text[];
BEGIN
  SELECT COUNT(*) INTO v_attempts
  FROM employee_login_attempts
  WHERE employee_code = upper(trim(p_employee_code))
    AND success = false
    AND created_at > now() - interval '15 minutes';

  IF v_attempts >= 8 THEN
    INSERT INTO employee_login_attempts (employee_code, success, ip_hint)
    VALUES (upper(trim(p_employee_code)), false, p_ip_hint);
    RETURN jsonb_build_object('success', false, 'message', 'rate_limited');
  END IF;

  SELECT * INTO v_emp
  FROM employees
  WHERE employee_code = upper(trim(p_employee_code))
    AND employment_status = 'active'
  FOR UPDATE;

  IF NOT FOUND OR v_emp.secret_hash <> crypt(p_secret_code, v_emp.secret_hash) THEN
    INSERT INTO employee_login_attempts (employee_code, success, ip_hint)
    VALUES (upper(trim(p_employee_code)), false, p_ip_hint);
    RETURN jsonb_build_object('success', false, 'message', 'invalid_credentials');
  END IF;

  SELECT * INTO v_dept FROM employee_departments WHERE id = v_emp.department_id;
  SELECT * INTO v_role FROM employee_roles WHERE id = v_emp.role_id;

  SELECT coalesce(array_agg(p.code ORDER BY p.code), ARRAY[]::text[])
  INTO v_perms
  FROM employee_role_permissions rp
  JOIN employee_permissions p ON p.id = rp.permission_id
  WHERE rp.role_id = v_emp.role_id;

  v_token := encode(gen_random_bytes(32), 'hex');
  v_expires := now() + interval '12 hours';

  INSERT INTO employee_sessions (
    employee_id, token_hash, refresh_token_hash, expires_at, ip_hint, user_agent
  ) VALUES (
    v_emp.id,
    encode(digest(v_token, 'sha256'), 'hex'),
    encode(digest(encode(gen_random_bytes(32), 'hex'), 'sha256'), 'hex'),
    v_expires,
    p_ip_hint,
    p_user_agent
  );

  UPDATE employees SET last_login_at = now(), updated_at = now() WHERE id = v_emp.id;

  INSERT INTO employee_login_attempts (employee_code, success, ip_hint)
  VALUES (v_emp.employee_code, true, p_ip_hint);

  PERFORM employee_write_audit(v_emp.id, 'login', 'employee', v_emp.id::text, NULL, NULL, NULL, p_ip_hint);

  RETURN jsonb_build_object(
    'success', true,
    'session_token', v_token,
    'expires_at', v_expires,
    'permissions', to_jsonb(v_perms),
    'employee', jsonb_build_object(
      'id', v_emp.id,
      'employee_code', v_emp.employee_code,
      'full_name', v_emp.full_name,
      'profile_photo_url', v_emp.profile_photo_url,
      'job_title', v_emp.job_title,
      'country_code', v_emp.country_code,
      'branch_code', v_emp.branch_code,
      'region', v_emp.region,
      'employment_status', v_emp.employment_status,
      'joining_date', v_emp.joining_date,
      'last_login_at', v_emp.last_login_at,
      'department', jsonb_build_object(
        'id', v_dept.id, 'code', v_dept.code,
        'name_en', v_dept.name_en, 'name_ar', v_dept.name_ar, 'name_ku', v_dept.name_ku
      ),
      'role', jsonb_build_object(
        'id', v_role.id, 'code', v_role.code,
        'name_en', v_role.name_en, 'name_ar', v_role.name_ar, 'name_ku', v_role.name_ku
      )
    )
  );
END;
$$;

CREATE OR REPLACE FUNCTION employee_logout(p_session_token text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE employee_sessions
  SET revoked_at = now()
  WHERE token_hash = encode(digest(p_session_token, 'sha256'), 'hex')
    AND revoked_at IS NULL;
  RETURN jsonb_build_object('success', true);
END;
$$;

-- ── Office Management: create office with credentials ───────────────────────
CREATE OR REPLACE FUNCTION employee_create_office(
  p_session_token text,
  p_name text,
  p_owner_full_name text,
  p_owner_phone text,
  p_office_phone text,
  p_email text,
  p_country_code text,
  p_city text,
  p_region text,
  p_address text,
  p_license_number text,
  p_office_type text DEFAULT 'partner',
  p_latitude double precision DEFAULT NULL,
  p_longitude double precision DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_emp_id uuid;
  v_code text;
  v_secret text;
  v_office_id uuid;
  v_seq integer;
BEGIN
  v_emp_id := employee_session_employee_id(p_session_token);
  IF v_emp_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;
  IF NOT employee_has_permission(v_emp_id, 'offices.create') THEN
    RETURN jsonb_build_object('success', false, 'message', 'forbidden');
  END IF;

  SELECT COUNT(*)::integer + 1 INTO v_seq FROM offices WHERE country_code = upper(p_country_code);
  v_code := upper(p_country_code) || '-OFF-' || lpad(v_seq::text, 5, '0');
  v_secret := encode(gen_random_bytes(6), 'hex');

  INSERT INTO offices (
    office_code, secret_hash, name, country_code, currency_code,
    address, phone, manager_name, license_number, status,
    owner_full_name, email, city, region, office_type, latitude, longitude,
    created_by_employee_id
  ) VALUES (
    v_code, crypt(v_secret, gen_salt('bf')), p_name, upper(p_country_code),
    CASE WHEN upper(p_country_code) = 'IQ' THEN 'IQD' ELSE 'USD' END,
    p_address, p_office_phone, p_owner_full_name, p_license_number, 'pending',
    p_owner_full_name, p_email, p_city, p_region, p_office_type, p_latitude, p_longitude,
    v_emp_id
  ) RETURNING id INTO v_office_id;

  PERFORM employee_write_audit(
    v_emp_id, 'office.create', 'office', v_office_id::text,
    NULL, v_code, 'Created office', NULL
  );

  RETURN jsonb_build_object(
    'success', true,
    'office_id', v_office_id,
    'office_code', v_code,
    'temporary_secret', v_secret,
    'status', 'pending'
  );
END;
$$;

CREATE OR REPLACE FUNCTION employee_set_office_status(
  p_session_token text,
  p_office_id uuid,
  p_status text,
  p_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_emp_id uuid;
  v_old text;
  v_perm text;
BEGIN
  v_emp_id := employee_session_employee_id(p_session_token);
  IF v_emp_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;

  v_perm := CASE
    WHEN p_status IN ('suspended','blocked','closed') THEN 'offices.suspend'
    ELSE 'offices.edit'
  END;
  IF NOT employee_has_permission(v_emp_id, v_perm) THEN
    RETURN jsonb_build_object('success', false, 'message', 'forbidden');
  END IF;

  SELECT status INTO v_old FROM offices WHERE id = p_office_id;
  IF v_old IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'not_found');
  END IF;

  UPDATE offices SET status = p_status, updated_at = now() WHERE id = p_office_id;
  PERFORM employee_write_audit(
    v_emp_id, 'office.status_change', 'office', p_office_id::text,
    v_old, p_status, p_reason, NULL
  );
  RETURN jsonb_build_object('success', true, 'status', p_status);
END;
$$;

CREATE OR REPLACE FUNCTION employee_reset_office_secret(
  p_session_token text,
  p_office_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_emp_id uuid;
  v_secret text;
BEGIN
  v_emp_id := employee_session_employee_id(p_session_token);
  IF v_emp_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;
  IF NOT employee_has_permission(v_emp_id, 'offices.credentials.reset') THEN
    RETURN jsonb_build_object('success', false, 'message', 'forbidden');
  END IF;

  v_secret := encode(gen_random_bytes(6), 'hex');
  UPDATE offices SET secret_hash = crypt(v_secret, gen_salt('bf')), updated_at = now()
  WHERE id = p_office_id;

  PERFORM employee_write_audit(
    v_emp_id, 'office.reset_secret', 'office', p_office_id::text,
    NULL, 'rotated', 'Secret regenerated', NULL
  );

  RETURN jsonb_build_object('success', true, 'temporary_secret', v_secret);
END;
$$;

-- ── Bank: send buyer OTP + verify + confirm deposit ─────────────────────────
CREATE OR REPLACE FUNCTION bank_request_buyer_otp(
  p_session_token text,
  p_transaction_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_emp_id uuid;
  v_phone text;
  v_otp text;
  v_masked text;
BEGIN
  v_emp_id := employee_session_employee_id(p_session_token);
  IF v_emp_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;
  IF NOT employee_has_permission(v_emp_id, 'bank.verify') THEN
    RETURN jsonb_build_object('success', false, 'message', 'forbidden');
  END IF;

  SELECT buyer_phone INTO v_phone FROM transactions WHERE id = p_transaction_id;
  IF v_phone IS NULL OR length(trim(v_phone)) < 4 THEN
    RETURN jsonb_build_object('success', false, 'message', 'buyer_phone_missing');
  END IF;

  v_otp := lpad((floor(random() * 1000000))::int::text, 6, '0');
  INSERT INTO bank_buyer_otps (
    transaction_id, phone, otp_hash, expires_at, requested_by_employee_id
  ) VALUES (
    p_transaction_id, v_phone, crypt(v_otp, gen_salt('bf')),
    now() + interval '10 minutes', v_emp_id
  );

  PERFORM employee_write_audit(
    v_emp_id, 'bank.otp_requested', 'transaction', p_transaction_id::text,
    NULL, 'otp_sent', NULL, NULL
  );

  v_masked := '**' || right(v_phone, 4);
  -- OTP returned only for secure channel integration / lab; production should SMS-only.
  RETURN jsonb_build_object(
    'success', true,
    'phone_masked', v_masked,
    'expires_in_seconds', 600,
    'delivery', 'queued',
    'debug_otp', v_otp
  );
END;
$$;

CREATE OR REPLACE FUNCTION bank_verify_buyer_otp(
  p_session_token text,
  p_transaction_id uuid,
  p_otp text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_emp_id uuid;
  v_row bank_buyer_otps%ROWTYPE;
BEGIN
  v_emp_id := employee_session_employee_id(p_session_token);
  IF v_emp_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;
  IF NOT employee_has_permission(v_emp_id, 'bank.verify') THEN
    RETURN jsonb_build_object('success', false, 'message', 'forbidden');
  END IF;

  SELECT * INTO v_row
  FROM bank_buyer_otps
  WHERE transaction_id = p_transaction_id
    AND verified_at IS NULL
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'otp_not_found');
  END IF;
  IF v_row.expires_at < now() THEN
    RETURN jsonb_build_object('success', false, 'message', 'otp_expired');
  END IF;
  IF v_row.attempts >= v_row.max_attempts THEN
    PERFORM employee_write_audit(v_emp_id, 'bank.otp_locked', 'transaction', p_transaction_id::text);
    RETURN jsonb_build_object('success', false, 'message', 'otp_locked');
  END IF;

  IF v_row.otp_hash <> crypt(p_otp, v_row.otp_hash) THEN
    UPDATE bank_buyer_otps SET attempts = attempts + 1 WHERE id = v_row.id;
    PERFORM employee_write_audit(v_emp_id, 'bank.otp_failed', 'transaction', p_transaction_id::text);
    RETURN jsonb_build_object('success', false, 'message', 'otp_invalid');
  END IF;

  UPDATE bank_buyer_otps SET verified_at = now() WHERE id = v_row.id;
  UPDATE transactions
  SET buyer_identity_verified = true, updated_at = now()
  WHERE id = p_transaction_id;

  PERFORM employee_write_audit(v_emp_id, 'bank.otp_verified', 'transaction', p_transaction_id::text);
  RETURN jsonb_build_object('success', true, 'identity_confirmed', true);
END;
$$;

CREATE OR REPLACE FUNCTION bank_confirm_deposit(
  p_session_token text,
  p_transaction_id uuid,
  p_actual_amount numeric,
  p_reference_number text,
  p_deposit_date date,
  p_allow_partial boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_emp_id uuid;
  v_required numeric;
  v_status text;
  v_deposit_id uuid;
  v_receipt_id uuid;
  v_buyer text;
  v_number text;
BEGIN
  v_emp_id := employee_session_employee_id(p_session_token);
  IF v_emp_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;
  IF NOT employee_has_permission(v_emp_id, 'bank.deposit.confirm') THEN
    RETURN jsonb_build_object('success', false, 'message', 'forbidden');
  END IF;

  SELECT required_escrow_amount, buyer_phone, transaction_number
  INTO v_required, v_buyer, v_number
  FROM transactions WHERE id = p_transaction_id;

  IF v_required IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'required_amount_missing');
  END IF;

  IF p_actual_amount = v_required THEN
    v_status := 'confirmed';
  ELSIF p_actual_amount < v_required THEN
    IF NOT (p_allow_partial AND employee_has_permission(v_emp_id, 'bank.partial_deposit')) THEN
      RETURN jsonb_build_object('success', false, 'message', 'amount_mismatch');
    END IF;
    v_status := 'partial';
  ELSE
    RETURN jsonb_build_object('success', false, 'message', 'amount_exceeds_required');
  END IF;

  INSERT INTO transaction_deposits (
    transaction_id, required_amount, actual_amount, reference_number,
    deposit_date, status, confirmed_by_employee_id, verified_buyer_at, confirmed_at
  ) VALUES (
    p_transaction_id, v_required, p_actual_amount, p_reference_number,
    p_deposit_date, v_status, v_emp_id, now(), now()
  ) RETURNING id INTO v_deposit_id;

  UPDATE transactions SET
    deposited_escrow_amount = COALESCE(deposited_escrow_amount, 0) + p_actual_amount,
    financial_status = CASE
      WHEN v_status = 'confirmed' THEN 'deposit_confirmed'
      ELSE 'partially_deposited'
    END,
    updated_at = now()
  WHERE id = p_transaction_id;

  INSERT INTO bank_deposit_receipts (
    transaction_id, deposit_id, amount, reference_number, deposit_date,
    verified_by_employee_id, buyer_phone
  ) VALUES (
    p_transaction_id, v_deposit_id, p_actual_amount, p_reference_number,
    p_deposit_date, v_emp_id, v_buyer
  ) RETURNING id INTO v_receipt_id;

  PERFORM employee_write_audit(
    v_emp_id, 'bank.deposit_confirm', 'transaction', p_transaction_id::text,
    v_required::text, p_actual_amount::text, v_status, NULL
  );

  RETURN jsonb_build_object(
    'success', true,
    'deposit_id', v_deposit_id,
    'receipt_id', v_receipt_id,
    'status', v_status,
    'transaction_number', v_number
  );
END;
$$;

-- ── Finance: update financial fields with audit ─────────────────────────────
CREATE OR REPLACE FUNCTION finance_update_transaction_amounts(
  p_session_token text,
  p_transaction_id uuid,
  p_required_escrow numeric DEFAULT NULL,
  p_company_fees numeric DEFAULT NULL,
  p_tax_amount numeric DEFAULT NULL,
  p_office_commission numeric DEFAULT NULL,
  p_bank_fees numeric DEFAULT NULL,
  p_seller_net numeric DEFAULT NULL,
  p_financial_status text DEFAULT NULL,
  p_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_emp_id uuid;
  v_old transactions%ROWTYPE;
BEGIN
  v_emp_id := employee_session_employee_id(p_session_token);
  IF v_emp_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;
  IF NOT employee_has_permission(v_emp_id, 'financial.edit') THEN
    RETURN jsonb_build_object('success', false, 'message', 'forbidden');
  END IF;

  SELECT * INTO v_old FROM transactions WHERE id = p_transaction_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'not_found');
  END IF;

  UPDATE transactions SET
    required_escrow_amount = COALESCE(p_required_escrow, required_escrow_amount),
    company_fees = COALESCE(p_company_fees, company_fees),
    tax_amount = COALESCE(p_tax_amount, tax_amount),
    office_commission_amount = COALESCE(p_office_commission, office_commission_amount),
    bank_fees = COALESCE(p_bank_fees, bank_fees),
    seller_net_amount = COALESCE(p_seller_net, seller_net_amount),
    financial_status = COALESCE(p_financial_status, financial_status),
    updated_at = now()
  WHERE id = p_transaction_id;

  PERFORM employee_write_audit(
    v_emp_id, 'finance.update_amounts', 'transaction', p_transaction_id::text,
    jsonb_build_object(
      'required_escrow', v_old.required_escrow_amount,
      'company_fees', v_old.company_fees,
      'tax', v_old.tax_amount
    )::text,
    jsonb_build_object(
      'required_escrow', COALESCE(p_required_escrow, v_old.required_escrow_amount),
      'company_fees', COALESCE(p_company_fees, v_old.company_fees),
      'tax', COALESCE(p_tax_amount, v_old.tax_amount)
    )::text,
    p_reason,
    NULL
  );

  RETURN jsonb_build_object('success', true);
END;
$$;

COMMENT ON TABLE employees IS 'Internal company employees — separate from users and partner offices.';
COMMENT ON FUNCTION employee_login IS 'Rate-limited employee auth returning opaque session + permissions.';
COMMENT ON FUNCTION employee_has_permission IS 'Backend RBAC check — never rely on UI alone.';
