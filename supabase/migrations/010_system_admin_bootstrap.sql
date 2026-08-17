-- 010: One-time System Admin bootstrap (no plaintext password in repo)
--
-- Department/role already seeded in 008. This migration:
-- 1) Creates SYS-001 shell with phone 07740080310 and an unusable random hash
-- 2) Exposes system_admin_complete_bootstrap(p_secret) — call ONCE from Supabase SQL Editor
-- 3) Allows employee_login with Employee ID OR phone number
--
-- NEVER commit the bootstrap secret. Run in dashboard after migrate:
--   SELECT system_admin_complete_bootstrap('YOUR_SECRET_HERE');

INSERT INTO system_config (key, value)
VALUES (
  'bootstrap.system_admin',
  jsonb_build_object('completed', false, 'employee_code', 'SYS-001')
)
ON CONFLICT (key) DO NOTHING;

DO $$
DECLARE
  v_dept_id uuid;
  v_role_id uuid;
BEGIN
  SELECT id INTO v_dept_id FROM employee_departments WHERE code = 'system_admin';
  SELECT id INTO v_role_id FROM employee_roles WHERE code = 'system_administrator';
  IF v_dept_id IS NULL OR v_role_id IS NULL THEN
    RAISE NOTICE 'system_admin department/role missing — apply 008 first';
    RETURN;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM employees WHERE employee_code = 'SYS-001') THEN
    INSERT INTO employees (
      employee_code,
      secret_hash,
      full_name,
      phone,
      job_title,
      department_id,
      role_id,
      country_code,
      employment_status,
      joining_date,
      must_change_password,
      two_factor_enabled
    ) VALUES (
      'SYS-001',
      -- Unusable until system_admin_complete_bootstrap is called
      crypt(encode(gen_random_bytes(32), 'hex'), gen_salt('bf')),
      'System Administrator',
      '07740080310',
      'System Administrator',
      v_dept_id,
      v_role_id,
      'IQ',
      'active',
      CURRENT_DATE,
      true,
      false
    );
  ELSE
    UPDATE employees
    SET phone = COALESCE(nullif(trim(phone), ''), '07740080310'),
        updated_at = now()
    WHERE employee_code = 'SYS-001'
      AND (phone IS NULL OR trim(phone) = '');
  END IF;
END $$;

CREATE OR REPLACE FUNCTION system_admin_complete_bootstrap(p_secret text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_cfg jsonb;
  v_emp_id uuid;
BEGIN
  SELECT value INTO v_cfg
  FROM system_config
  WHERE key = 'bootstrap.system_admin'
  FOR UPDATE;

  IF v_cfg IS NULL THEN
    INSERT INTO system_config (key, value)
    VALUES (
      'bootstrap.system_admin',
      jsonb_build_object('completed', false, 'employee_code', 'SYS-001')
    );
    v_cfg := jsonb_build_object('completed', false, 'employee_code', 'SYS-001');
  END IF;

  IF COALESCE((v_cfg->>'completed')::boolean, false) THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'bootstrap_already_completed',
      'hint', 'Use hr_set_employee_secret or change-password flow to rotate credentials.'
    );
  END IF;

  IF p_secret IS NULL OR length(trim(p_secret)) < 6 THEN
    RETURN jsonb_build_object('success', false, 'message', 'secret_too_short');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM employees WHERE employee_code = 'SYS-001') THEN
    RETURN jsonb_build_object('success', false, 'message', 'sys_001_missing_apply_migration');
  END IF;

  UPDATE employees SET
    secret_hash = crypt(trim(p_secret), gen_salt('bf')),
    phone = COALESCE(nullif(trim(phone), ''), '07740080310'),
    must_change_password = true,
    temporary_secret_issued_at = now(),
    updated_at = now()
  WHERE employee_code = 'SYS-001'
  RETURNING id INTO v_emp_id;

  UPDATE system_config SET
    value = jsonb_build_object(
      'completed', true,
      'employee_code', 'SYS-001',
      'completed_at', to_jsonb(now())
    ),
    updated_at = now(),
    updated_by_employee_id = v_emp_id
  WHERE key = 'bootstrap.system_admin';

  PERFORM employee_write_audit(
    v_emp_id,
    'system_admin_bootstrap_completed',
    'employee',
    v_emp_id::text,
    NULL,
    'SYS-001',
    'one_time_bootstrap',
    NULL
  );

  RETURN jsonb_build_object(
    'success', true,
    'employee_code', 'SYS-001',
    'phone', '07740080310',
    'must_change_password', true,
    'message', 'Bootstrap complete. Log in with SYS-001 or phone, then rotate the secret.'
  );
END;
$$;

COMMENT ON FUNCTION system_admin_complete_bootstrap(text) IS
  'ONE-TIME: set SYS-001 secret via Supabase SQL Editor. Do not embed the secret in app or git.';

-- Login accepts Employee ID (SYS-001) or phone (07740080310 / +9647740080310)
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
  v_login_key text;
  v_phone_norm text;
BEGIN
  v_login_key := upper(trim(p_employee_code));
  -- Normalize Iraqi local mobiles: 07XXXXXXXXX → keep as stored; also try +9647…
  v_phone_norm := regexp_replace(trim(p_employee_code), '[^0-9+]', '', 'g');
  IF v_phone_norm ~ '^9647[0-9]{9}$' THEN
    v_phone_norm := '0' || substr(v_phone_norm, 4);
  ELSIF v_phone_norm ~ '^\+9647[0-9]{9}$' THEN
    v_phone_norm := '0' || substr(v_phone_norm, 5);
  END IF;

  SELECT COUNT(*) INTO v_attempts
  FROM employee_login_attempts
  WHERE employee_code = v_login_key
    AND success = false
    AND created_at > now() - interval '15 minutes';

  IF v_attempts >= 8 THEN
    INSERT INTO employee_login_attempts (employee_code, success, ip_hint)
    VALUES (v_login_key, false, p_ip_hint);
    RETURN jsonb_build_object('success', false, 'message', 'rate_limited');
  END IF;

  SELECT * INTO v_emp
  FROM employees
  WHERE employment_status = 'active'
    AND (
      employee_code = v_login_key
      OR phone = trim(p_employee_code)
      OR phone = v_phone_norm
    )
  FOR UPDATE;

  IF NOT FOUND OR v_emp.secret_hash <> crypt(p_secret_code, v_emp.secret_hash) THEN
    INSERT INTO employee_login_attempts (employee_code, success, ip_hint)
    VALUES (v_login_key, false, p_ip_hint);
    RETURN jsonb_build_object('success', false, 'message', 'invalid_credentials');
  END IF;

  -- Reject login until one-time bootstrap completed for SYS-001
  IF v_emp.employee_code = 'SYS-001' THEN
    IF EXISTS (
      SELECT 1 FROM system_config
      WHERE key = 'bootstrap.system_admin'
        AND COALESCE((value->>'completed')::boolean, false) = false
    ) THEN
      INSERT INTO employee_login_attempts (employee_code, success, ip_hint)
      VALUES (v_emp.employee_code, false, p_ip_hint);
      RETURN jsonb_build_object(
        'success', false,
        'message', 'bootstrap_required',
        'hint', 'Run SELECT system_admin_complete_bootstrap(''…'') in Supabase SQL Editor once.'
      );
    END IF;
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
    'must_change_password', COALESCE(v_emp.must_change_password, false),
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
        'id', v_dept.id,
        'code', v_dept.code,
        'name_en', v_dept.name_en,
        'name_ar', v_dept.name_ar,
        'name_ku', v_dept.name_ku
      ),
      'role', jsonb_build_object(
        'id', v_role.id,
        'code', v_role.code,
        'name_en', v_role.name_en,
        'name_ar', v_role.name_ar,
        'name_ku', v_role.name_ku
      )
    ),
    'permissions', to_jsonb(v_perms)
  );
END;
$$;
