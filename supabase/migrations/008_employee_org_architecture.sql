-- 008: Employee org architecture — UX-aligned RBAC, Sales, Legal, HR, support roles
-- Extends 006/007. Passwords never stored in plaintext.

-- ── Employee profile extensions ─────────────────────────────────────────────
ALTER TABLE employees
  ADD COLUMN IF NOT EXISTS phone text,
  ADD COLUMN IF NOT EXISTS email text,
  ADD COLUMN IF NOT EXISTS employment_type text DEFAULT 'full_time',
  ADD COLUMN IF NOT EXISTS manager_id uuid REFERENCES employees(id),
  ADD COLUMN IF NOT EXISTS address_text text,
  ADD COLUMN IF NOT EXISTS emergency_contact text,
  ADD COLUMN IF NOT EXISTS must_change_password boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS two_factor_enabled boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS phone_verified_at timestamptz,
  ADD COLUMN IF NOT EXISTS temporary_secret_issued_at timestamptz;

-- Expand employment_status values (app-enforced): active | on_leave | suspended |
-- probation | resigned | terminated | archived

CREATE TABLE IF NOT EXISTS employee_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  doc_type text NOT NULL, -- contract | id | certificate | legal | promotion | warning
  title text NOT NULL,
  storage_path text,
  media_url text,
  notes text,
  uploaded_by_employee_id uuid REFERENCES employees(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS employee_attendance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  work_date date NOT NULL DEFAULT CURRENT_DATE,
  status text NOT NULL DEFAULT 'present', -- present | absent | leave | remote
  check_in_at timestamptz,
  check_out_at timestamptz,
  notes text,
  UNIQUE (employee_id, work_date)
);

-- ── Departments (org tree) ──────────────────────────────────────────────────
INSERT INTO employee_departments (code, name_en, name_ar, name_ku)
SELECT v.code, v.name_en, v.name_ar, v.name_ku
FROM (VALUES
  ('hr', 'Human Resources', 'الموارد البشرية', 'سەرچاوە مرۆییەکان'),
  ('sales', 'Sales', 'المبيعات', 'فرۆشتن'),
  ('contract_lawyer', 'Contract Lawyers', 'محامو العقود', 'پارێزەرانی گرێبەست'),
  ('transaction_lawyer', 'Transaction Lawyers', 'محامو المعاملات', 'پارێزەرانی مامەڵە'),
  ('closing', 'Closing Team', 'فريق الإغلاق', 'تیمی داخستن'),
  ('support', 'Customer Support', 'دعم العملاء', 'پشتگیری کڕیار'),
  ('quality', 'Property Quality', 'جودة العقارات', 'کوالیتی خانووبەرە'),
  ('compliance', 'Compliance', 'الامتثال', 'پابەندبوون'),
  ('system_admin', 'System Administration', 'إدارة النظام', 'بەڕێوەبردنی سیستەم'),
  ('executive', 'Executive', 'الإدارة التنفيذية', 'بەڕێوەبەرایەتی')
) AS v(code, name_en, name_ar, name_ku)
WHERE NOT EXISTS (
  SELECT 1 FROM employee_departments d WHERE d.code = v.code
);

-- ── Granular permissions ────────────────────────────────────────────────────
INSERT INTO employee_permissions (code, description)
SELECT v.code, v.description
FROM (VALUES
  ('property.read', 'Read property intelligence'),
  ('property.edit', 'Edit property data'),
  ('property.publish', 'Publish properties'),
  ('transaction.read', 'Read transactions'),
  ('transaction.edit', 'Edit transactions'),
  ('finance.read', 'Read finance (alias family)'),
  ('finance.edit', 'Edit finance'),
  ('finance.set_fee', 'Set fees'),
  ('contract.create', 'Create contracts'),
  ('contract.edit', 'Edit contracts'),
  ('contract.approve', 'Approve contracts'),
  ('contract.deliver', 'Deliver contracts to parties'),
  ('employee.create', 'Create employees'),
  ('employee.edit', 'Edit employees'),
  ('employee.suspend', 'Suspend employees'),
  ('employee.reset_credentials', 'Reset employee credentials'),
  ('employee.assign_role', 'Assign roles (non super-admin)'),
  ('sales.leads.view', 'View sales leads'),
  ('sales.leads.edit', 'Edit sales leads'),
  ('sales.clients.view', 'View sales clients'),
  ('sales.handoff', 'Hand off to closing'),
  ('sales.property_request', 'Create publishing request from sales'),
  ('legal.transaction.manage', 'Manage legal transaction procedures'),
  ('legal.ownership.transfer', 'Record ownership transfer'),
  ('closing.manage', 'Manage closing process'),
  ('support.tickets', 'Handle support tickets'),
  ('quality.review', 'Quality review properties'),
  ('compliance.review', 'Compliance review'),
  ('system.config', 'System configuration'),
  ('executive.view', 'Executive analytics view'),
  ('hr.view', 'View HR directory'),
  ('hr.manage', 'Manage HR operations')
) AS v(code, description)
WHERE NOT EXISTS (
  SELECT 1 FROM employee_permissions p WHERE p.code = v.code
);

-- ── Roles ───────────────────────────────────────────────────────────────────
INSERT INTO employee_roles (code, name_en, name_ar, name_ku, department_id)
SELECT v.code, v.name_en, v.name_ar, v.name_ku, d.id
FROM (VALUES
  ('hr_officer', 'HR Officer', 'موظف موارد بشرية', 'کارمەندی HR', 'hr'),
  ('sales_officer', 'Sales Officer', 'موظف مبيعات', 'کارمەندی فرۆشتن', 'sales'),
  ('contract_lawyer', 'Contract Lawyer', 'محامي عقود', 'پارێزەری گرێبەست', 'contract_lawyer'),
  ('transaction_lawyer', 'Transaction Lawyer', 'محامي معاملات', 'پارێزەری مامەڵە', 'transaction_lawyer'),
  ('closing_officer', 'Closing Officer', 'موظف إغلاق', 'کارمەندی داخستن', 'closing'),
  ('support_agent', 'Support Agent', 'وكيل دعم', 'بریکاری پشتگیری', 'support'),
  ('quality_reviewer', 'Quality Reviewer', 'مراجع جودة', 'پێداچوونەوەی کوالیتی', 'quality'),
  ('compliance_officer', 'Compliance Officer', 'ضابط امتثال', 'ئەفسەری پابەندبوون', 'compliance'),
  ('system_administrator', 'System Administrator', 'مدير نظام', 'بەڕێوەبەری سیستەم', 'system_admin'),
  ('executive_viewer', 'Executive Viewer', 'عرض تنفيذي', 'بینینی جێبەجێکاری', 'executive')
) AS v(code, name_en, name_ar, name_ku, dept_code)
JOIN employee_departments d ON d.code = v.dept_code
WHERE NOT EXISTS (SELECT 1 FROM employee_roles r WHERE r.code = v.code);

-- Role permissions helper
CREATE OR REPLACE FUNCTION _emp_grant_role_perms(p_role text, p_perms text[])
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_role_id uuid;
  v_code text;
BEGIN
  SELECT id INTO v_role_id FROM employee_roles WHERE code = p_role;
  IF v_role_id IS NULL THEN RETURN; END IF;
  FOREACH v_code IN ARRAY p_perms LOOP
    INSERT INTO employee_role_permissions (role_id, permission_id)
    SELECT v_role_id, p.id FROM employee_permissions p WHERE p.code = v_code
    ON CONFLICT DO NOTHING;
  END LOOP;
END;
$$;

SELECT _emp_grant_role_perms('hr_officer', ARRAY[
  'hr.view','hr.manage','employee.create','employee.edit','employee.suspend',
  'employee.reset_credentials','employee.assign_role','audit.view','messages.view',
  'messages.send','search.global','reports.view'
]);

SELECT _emp_grant_role_perms('sales_officer', ARRAY[
  'sales.leads.view','sales.leads.edit','sales.clients.view','sales.handoff',
  'sales.property_request','publishing.create','property.read','messages.view',
  'messages.send','search.global','reports.view'
]);

SELECT _emp_grant_role_perms('contract_lawyer', ARRAY[
  'contract.create','contract.edit','contract.approve','contract.deliver',
  'transaction.read','property.read','messages.view','messages.send',
  'search.global','audit.view'
]);

SELECT _emp_grant_role_perms('transaction_lawyer', ARRAY[
  'legal.transaction.manage','legal.ownership.transfer','transaction.read',
  'transaction.edit','contract.create','property.read','messages.view',
  'messages.send','search.global','audit.view'
]);

SELECT _emp_grant_role_perms('closing_officer', ARRAY[
  'closing.manage','transaction.read','transaction.edit','transactions.create',
  'sales.clients.view','messages.view','messages.send','search.global'
]);

SELECT _emp_grant_role_perms('support_agent', ARRAY[
  'support.tickets','messages.view','messages.send','property.read',
  'transaction.read','search.global'
]);

SELECT _emp_grant_role_perms('quality_reviewer', ARRAY[
  'quality.review','property.read','property.edit','publishing.review',
  'messages.view','search.global'
]);

SELECT _emp_grant_role_perms('compliance_officer', ARRAY[
  'compliance.review','audit.view','transaction.read','property.read',
  'search.global','reports.view'
]);

SELECT _emp_grant_role_perms('system_administrator', ARRAY[
  'system.config','audit.view','search.global','messages.view','reports.view'
]);

SELECT _emp_grant_role_perms('executive_viewer', ARRAY[
  'executive.view','reports.view','reports.export','search.global'
]);

-- ── Sales leads / clients ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sales_leads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_code text NOT NULL UNIQUE,
  full_name text NOT NULL,
  phone text NOT NULL,
  lead_type text NOT NULL DEFAULT 'buyer', -- buyer | seller | renter
  property_interest text,
  budget_text text,
  preferred_area text,
  source text,
  status text NOT NULL DEFAULT 'new',
  -- new | contacted | qualified | viewing | negotiating | ready_for_closing | converted | lost
  assigned_employee_id uuid REFERENCES employees(id),
  property_asset_id uuid REFERENCES property_assets(id),
  notes text,
  next_follow_up_at timestamptz,
  created_by_employee_id uuid REFERENCES employees(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sales_leads_assigned
  ON sales_leads (assigned_employee_id, status);

CREATE TABLE IF NOT EXISTS sales_follow_ups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id uuid NOT NULL REFERENCES sales_leads(id) ON DELETE CASCADE,
  employee_id uuid NOT NULL REFERENCES employees(id),
  due_at timestamptz NOT NULL,
  completed_at timestamptz,
  channel text DEFAULT 'call', -- call | message | visit
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sales_lead_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id uuid NOT NULL REFERENCES sales_leads(id) ON DELETE CASCADE,
  sender_employee_id uuid REFERENCES employees(id),
  message_type text NOT NULL DEFAULT 'text', -- text | voice | image | document | location | property_card
  body text,
  media_url text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ── Contracts (contract lawyer) ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS legal_contract_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  name_en text NOT NULL,
  name_ar text,
  name_ku text,
  body_template text NOT NULL,
  -- supports {{buyer_name}} {{seller_name}} {{property_id}} etc.
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO legal_contract_templates (code, name_en, name_ar, name_ku, body_template)
SELECT * FROM (VALUES
  ('residential_sale', 'Residential Sale', 'بيع سكني', 'فرۆشتنی نیشتەجێ',
   E'عقد بيع عقار سكني\nرقم المعاملة: {{transaction_number}}\nالمشتري: {{buyer_name}}\nالبائع: {{seller_name}}\nرقم العقار: {{property_id}}\nالعنوان: {{property_address}}\nثمن البيع: {{sale_price}}\nالضرائب: {{taxes}}\nالتاريخ: {{date}}\n'),
  ('commercial_sale', 'Commercial Sale', 'بيع تجاري', 'فرۆشتنی بازرگانی',
   E'عقد بيع عقار تجاري\n{{transaction_number}} / {{buyer_name}} / {{seller_name}} / {{property_id}} / {{sale_price}} / {{date}}'),
  ('land_sale', 'Land Sale', 'بيع أرض', 'فرۆشتنی زەوی',
   E'عقد بيع أرض\n{{transaction_number}} / {{buyer_name}} / {{seller_name}} / {{property_id}} / {{property_address}} / {{sale_price}} / {{date}}'),
  ('agricultural', 'Agricultural Property', 'عقار زراعي', 'خانووبەرەی کشتوکاڵی',
   E'عقد عقار زراعي\n{{transaction_number}} / {{buyer_name}} / {{seller_name}} / {{property_id}} / {{sale_price}} / {{date}}'),
  ('rental', 'Rental', 'إيجار', 'کرێ',
   E'عقد إيجار\n{{transaction_number}} / {{buyer_name}} / {{seller_name}} / {{property_id}} / {{property_address}} / {{date}}'),
  ('lease_to_own', 'Lease-to-Own', 'إيجار منتهٍ بالتمليك', 'کرێ بۆ خاوەندارێتی',
   E'عقد إيجار منتهٍ بالتمليك\n{{transaction_number}} / {{buyer_name}} / {{seller_name}} / {{property_id}} / {{sale_price}} / {{date}}'),
  ('investment', 'Investment', 'استثمار', 'وەبەرهێنان',
   E'عقد استثماري\n{{transaction_number}} / {{buyer_name}} / {{seller_name}} / {{property_id}} / {{sale_price}} / {{date}}'),
  ('other', 'Other', 'أخرى', 'هیتر',
   E'عقد\n{{transaction_number}} / {{buyer_name}} / {{seller_name}} / {{property_id}} / {{date}}')
) AS v(code, name_en, name_ar, name_ku, body_template)
WHERE NOT EXISTS (SELECT 1 FROM legal_contract_templates LIMIT 1);

CREATE TABLE IF NOT EXISTS legal_contracts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid REFERENCES transactions(id),
  template_id uuid REFERENCES legal_contract_templates(id),
  status text NOT NULL DEFAULT 'draft',
  -- draft | awaiting_information | sent | awaiting_upload | awaiting_signature | completed | void
  version_no integer NOT NULL DEFAULT 1,
  version_label text NOT NULL DEFAULT 'Draft', -- Draft | Version N | Final
  body_text text NOT NULL DEFAULT '',
  variables jsonb NOT NULL DEFAULT '{}'::jsonb,
  pdf_url text,
  buyer_uploaded_at timestamptz,
  seller_uploaded_at timestamptz,
  created_by_employee_id uuid REFERENCES employees(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS legal_contract_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  contract_id uuid NOT NULL REFERENCES legal_contracts(id) ON DELETE CASCADE,
  version_no integer NOT NULL,
  version_label text NOT NULL,
  body_text text NOT NULL,
  changed_by_employee_id uuid REFERENCES employees(id),
  changed_fields jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (contract_id, version_no)
);

CREATE TABLE IF NOT EXISTS legal_contract_audit (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  contract_id uuid NOT NULL REFERENCES legal_contracts(id) ON DELETE CASCADE,
  changed_by_employee_id uuid REFERENCES employees(id),
  field_key text NOT NULL,
  old_value text,
  new_value text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ── Transaction lawyer procedures ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS legal_transaction_steps (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  step_key text NOT NULL,
  -- identity | documents | contract | escrow | ownership_document | settlement | agricultural_conditions
  step_order integer NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'pending', -- pending | active | completed | skipped
  assigned_employee_id uuid REFERENCES employees(id),
  notes text,
  evidence_url text,
  completed_at timestamptz,
  UNIQUE (transaction_id, step_key)
);

CREATE TABLE IF NOT EXISTS legal_ownership_transfers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  location_text text,
  scheduled_at timestamptz,
  government_office text,
  reference_number text,
  attendance_notes text,
  evidence_url text,
  responsible_employee_id uuid REFERENCES employees(id),
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS support_tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_code text NOT NULL UNIQUE,
  subject text NOT NULL,
  status text NOT NULL DEFAULT 'open', -- open | active | urgent | waiting | resolved
  priority text NOT NULL DEFAULT 'normal',
  assigned_employee_id uuid REFERENCES employees(id),
  related_entity_type text,
  related_entity_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS closing_cases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_code text NOT NULL UNIQUE,
  lead_id uuid REFERENCES sales_leads(id),
  transaction_id uuid REFERENCES transactions(id),
  buyer_name text,
  seller_name text,
  property_ref text,
  price_text text,
  office_id uuid REFERENCES offices(id),
  sales_employee_id uuid REFERENCES employees(id),
  closing_employee_id uuid REFERENCES employees(id),
  status text NOT NULL DEFAULT 'intake', -- intake | verifying | barcode | with_lawyer | handed_off
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ── Employee code generation ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION generate_employee_code(p_department_code text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  v_prefix text;
  v_next integer;
  v_code text;
BEGIN
  v_prefix := CASE lower(p_department_code)
    WHEN 'finance' THEN 'FIN'
    WHEN 'bank' THEN 'BANK'
    WHEN 'office_management' THEN 'OM'
    WHEN 'publishing' THEN 'PUB'
    WHEN 'information' THEN 'INFO'
    WHEN 'photography' THEN 'MEDIA'
    WHEN 'engineering' THEN 'MAP'
    WHEN 'sales' THEN 'SALES'
    WHEN 'contract_lawyer' THEN 'LAW-C'
    WHEN 'transaction_lawyer' THEN 'LAW-T'
    WHEN 'hr' THEN 'HR'
    WHEN 'closing' THEN 'CLOSE'
    WHEN 'support' THEN 'SUP'
    WHEN 'quality' THEN 'QC'
    WHEN 'compliance' THEN 'COMP'
    WHEN 'system_admin' THEN 'SYS'
    WHEN 'executive' THEN 'EXE'
    ELSE 'EMP'
  END;

  SELECT COALESCE(MAX(
    NULLIF(regexp_replace(employee_code, '^' || v_prefix || '-?', ''), '')::integer
  ), 0) + 1
  INTO v_next
  FROM employees
  WHERE employee_code ~ ('^' || v_prefix || '-?[0-9]+$');

  v_code := v_prefix || '-' || lpad(v_next::text, 3, '0');
  RETURN v_code;
END;
$$;

-- ── HR create employee (server-side hash) ───────────────────────────────────
CREATE OR REPLACE FUNCTION hr_create_employee(
  p_session_token text,
  p_full_name text,
  p_department_code text,
  p_role_code text,
  p_phone text DEFAULT NULL,
  p_email text DEFAULT NULL,
  p_job_title text DEFAULT NULL,
  p_branch_code text DEFAULT NULL,
  p_country_code text DEFAULT 'IQ',
  p_employment_type text DEFAULT 'full_time',
  p_manager_id uuid DEFAULT NULL,
  p_address_text text DEFAULT NULL,
  p_emergency_contact text DEFAULT NULL,
  p_temporary_secret text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_actor employees%ROWTYPE;
  v_session employee_sessions%ROWTYPE;
  v_dept employee_departments%ROWTYPE;
  v_role employee_roles%ROWTYPE;
  v_code text;
  v_secret text;
  v_id uuid;
  v_token_hash text;
BEGIN
  v_token_hash := encode(digest(p_session_token, 'sha256'), 'hex');
  SELECT s.* INTO v_session FROM employee_sessions s
  WHERE s.token_hash = v_token_hash AND s.revoked_at IS NULL AND s.expires_at > now();
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;
  SELECT * INTO v_actor FROM employees WHERE id = v_session.employee_id;
  IF NOT EXISTS (
    SELECT 1
    FROM employee_role_permissions rp
    JOIN employee_permissions p ON p.id = rp.permission_id
    WHERE rp.role_id = v_actor.role_id
      AND p.code IN ('employee.create', 'hr.manage')
  ) THEN
    RETURN jsonb_build_object('success', false, 'message', 'forbidden');
  END IF;

  -- Block assigning system_admin / executive via HR unless actor has system.config
  IF lower(p_role_code) IN ('system_administrator', 'super_admin') THEN
    IF NOT EXISTS (
      SELECT 1 FROM employee_role_permissions rp
      JOIN employee_permissions p ON p.id = rp.permission_id
      WHERE rp.role_id = v_actor.role_id AND p.code = 'system.config'
    ) THEN
      RETURN jsonb_build_object('success', false, 'message', 'cannot_assign_system_admin');
    END IF;
  END IF;

  SELECT * INTO v_dept FROM employee_departments WHERE code = lower(p_department_code);
  SELECT * INTO v_role FROM employee_roles WHERE code = lower(p_role_code);
  IF v_dept.id IS NULL OR v_role.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'invalid_department_or_role');
  END IF;

  v_code := generate_employee_code(v_dept.code);
  v_secret := COALESCE(nullif(trim(p_temporary_secret), ''), encode(gen_random_bytes(9), 'hex'));

  INSERT INTO employees (
    employee_code, secret_hash, full_name, phone, email, job_title,
    department_id, role_id, country_code, branch_code, employment_type,
    manager_id, address_text, emergency_contact, employment_status,
    joining_date, must_change_password, temporary_secret_issued_at
  ) VALUES (
    v_code, crypt(v_secret, gen_salt('bf')), trim(p_full_name), p_phone, p_email,
    p_job_title, v_dept.id, v_role.id, COALESCE(p_country_code, 'IQ'),
    p_branch_code, p_employment_type, p_manager_id, p_address_text,
    p_emergency_contact, 'active', CURRENT_DATE, true, now()
  ) RETURNING id INTO v_id;

  PERFORM employee_write_audit(
    v_actor.id, 'created_employee', 'employee', v_id::text, NULL, v_code, NULL
  );

  RETURN jsonb_build_object(
    'success', true,
    'employee_id', v_id,
    'employee_code', v_code,
    'temporary_password', v_secret
  );
END;
$$;

-- One-time HR bootstrap (no plaintext password in repo). Call once from secure ops:
-- SELECT hr_bootstrap_account('مصطفى ايمن محمد خضير', 'phone', 'email', '<secret>');
CREATE OR REPLACE FUNCTION hr_bootstrap_account(
  p_full_name text,
  p_phone text,
  p_email text,
  p_secret text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_dept_id uuid;
  v_role_id uuid;
  v_id uuid;
BEGIN
  IF EXISTS (SELECT 1 FROM employees e
             JOIN employee_departments d ON d.id = e.department_id
             WHERE d.code = 'hr') THEN
    RETURN jsonb_build_object('success', false, 'message', 'hr_already_exists');
  END IF;
  IF length(trim(p_secret)) < 10 THEN
    RETURN jsonb_build_object('success', false, 'message', 'secret_too_short');
  END IF;

  SELECT id INTO v_dept_id FROM employee_departments WHERE code = 'hr';
  SELECT id INTO v_role_id FROM employee_roles WHERE code = 'hr_officer';

  INSERT INTO employees (
    employee_code, secret_hash, full_name, phone, email, job_title,
    department_id, role_id, country_code, employment_status, joining_date,
    must_change_password, two_factor_enabled
  ) VALUES (
    'HR-001', crypt(p_secret, gen_salt('bf')), trim(p_full_name), p_phone, p_email,
    'HR Officer', v_dept_id, v_role_id, 'IQ', 'active', CURRENT_DATE, true, false
  ) RETURNING id INTO v_id;

  RETURN jsonb_build_object('success', true, 'employee_id', v_id, 'employee_code', 'HR-001');
END;
$$;

-- Seed HR-001 shell account with unusable random hash until bootstrap/set-secret.
-- Operator must call hr_bootstrap_account OR hr_set_employee_secret.
DO $$
DECLARE
  v_dept_id uuid;
  v_role_id uuid;
BEGIN
  SELECT id INTO v_dept_id FROM employee_departments WHERE code = 'hr';
  SELECT id INTO v_role_id FROM employee_roles WHERE code = 'hr_officer';
  IF v_dept_id IS NULL OR v_role_id IS NULL THEN RETURN; END IF;
  IF NOT EXISTS (SELECT 1 FROM employees WHERE employee_code = 'HR-001') THEN
    INSERT INTO employees (
      employee_code, secret_hash, full_name, phone, email, job_title,
      department_id, role_id, country_code, employment_status, joining_date,
      must_change_password
    ) VALUES (
      'HR-001',
      crypt(encode(gen_random_bytes(24), 'hex'), gen_salt('bf')),
      'مصطفى ايمن محمد خضير',
      NULL,
      'mostafa.a.mohammed.sc24@st.nahrainuniv.edu.iq',
      'HR Officer',
      v_dept_id,
      v_role_id,
      'IQ',
      'active',
      CURRENT_DATE,
      true
    );
  END IF;
END $$;

CREATE OR REPLACE FUNCTION hr_set_employee_secret(
  p_session_token text,
  p_employee_id uuid,
  p_new_secret text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_actor employees%ROWTYPE;
  v_session employee_sessions%ROWTYPE;
  v_token_hash text;
BEGIN
  v_token_hash := encode(digest(p_session_token, 'sha256'), 'hex');
  SELECT s.* INTO v_session FROM employee_sessions s
  WHERE s.token_hash = v_token_hash AND s.revoked_at IS NULL AND s.expires_at > now();
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;
  SELECT * INTO v_actor FROM employees WHERE id = v_session.employee_id;
  IF NOT EXISTS (
    SELECT 1 FROM employee_role_permissions rp
    JOIN employee_permissions p ON p.id = rp.permission_id
    WHERE rp.role_id = v_actor.role_id
      AND p.code IN ('employee.reset_credentials', 'hr.manage')
  ) THEN
    RETURN jsonb_build_object('success', false, 'message', 'forbidden');
  END IF;
  IF length(trim(p_new_secret)) < 8 THEN
    RETURN jsonb_build_object('success', false, 'message', 'secret_too_short');
  END IF;
  UPDATE employees SET
    secret_hash = crypt(p_new_secret, gen_salt('bf')),
    must_change_password = true,
    temporary_secret_issued_at = now(),
    updated_at = now()
  WHERE id = p_employee_id;
  PERFORM employee_write_audit(
    v_actor.id, 'reset_credentials', 'employee', p_employee_id::text, NULL, NULL, NULL
  );
  RETURN jsonb_build_object('success', true);
END;
$$;

-- ── Sales RPCs ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION sales_create_lead(
  p_session_token text,
  p_full_name text,
  p_phone text,
  p_lead_type text,
  p_budget_text text DEFAULT NULL,
  p_preferred_area text DEFAULT NULL,
  p_source text DEFAULT NULL,
  p_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_session employee_sessions%ROWTYPE;
  v_emp employees%ROWTYPE;
  v_token_hash text;
  v_id uuid;
  v_code text;
BEGIN
  v_token_hash := encode(digest(p_session_token, 'sha256'), 'hex');
  SELECT s.* INTO v_session FROM employee_sessions s
  WHERE s.token_hash = v_token_hash AND s.revoked_at IS NULL AND s.expires_at > now();
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;
  SELECT * INTO v_emp FROM employees WHERE id = v_session.employee_id;
  IF NOT EXISTS (
    SELECT 1 FROM employee_role_permissions rp
    JOIN employee_permissions p ON p.id = rp.permission_id
    WHERE rp.role_id = v_emp.role_id AND p.code = 'sales.leads.edit'
  ) THEN
    RETURN jsonb_build_object('success', false, 'message', 'forbidden');
  END IF;

  v_code := 'LEAD-' || to_char(now(), 'YYMMDD') || '-' || lpad((floor(random()*9999))::int::text, 4, '0');
  INSERT INTO sales_leads (
    lead_code, full_name, phone, lead_type, budget_text, preferred_area,
    source, notes, assigned_employee_id, created_by_employee_id
  ) VALUES (
    v_code, trim(p_full_name), trim(p_phone), COALESCE(p_lead_type, 'buyer'),
    p_budget_text, p_preferred_area, p_source, p_notes, v_emp.id, v_emp.id
  ) RETURNING id INTO v_id;

  RETURN jsonb_build_object('success', true, 'lead_id', v_id, 'lead_code', v_code);
END;
$$;

CREATE OR REPLACE FUNCTION contract_save_draft(
  p_session_token text,
  p_contract_id uuid,
  p_body_text text,
  p_version_label text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_session employee_sessions%ROWTYPE;
  v_emp employees%ROWTYPE;
  v_token_hash text;
  v_contract legal_contracts%ROWTYPE;
  v_next integer;
BEGIN
  v_token_hash := encode(digest(p_session_token, 'sha256'), 'hex');
  SELECT s.* INTO v_session FROM employee_sessions s
  WHERE s.token_hash = v_token_hash AND s.revoked_at IS NULL AND s.expires_at > now();
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;
  SELECT * INTO v_emp FROM employees WHERE id = v_session.employee_id;
  IF NOT EXISTS (
    SELECT 1 FROM employee_role_permissions rp
    JOIN employee_permissions p ON p.id = rp.permission_id
    WHERE rp.role_id = v_emp.role_id AND p.code IN ('contract.edit', 'contract.create')
  ) THEN
    RETURN jsonb_build_object('success', false, 'message', 'forbidden');
  END IF;

  SELECT * INTO v_contract FROM legal_contracts WHERE id = p_contract_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'not_found');
  END IF;

  INSERT INTO legal_contract_audit (contract_id, changed_by_employee_id, field_key, old_value, new_value)
  VALUES (p_contract_id, v_emp.id, 'body_text', left(v_contract.body_text, 2000), left(p_body_text, 2000));

  v_next := v_contract.version_no + 1;
  INSERT INTO legal_contract_versions (contract_id, version_no, version_label, body_text, changed_by_employee_id)
  VALUES (
    p_contract_id, v_next, COALESCE(p_version_label, 'Version ' || v_next),
    p_body_text, v_emp.id
  );

  UPDATE legal_contracts SET
    body_text = p_body_text,
    version_no = v_next,
    version_label = COALESCE(p_version_label, 'Version ' || v_next),
    updated_at = now()
  WHERE id = p_contract_id;

  RETURN jsonb_build_object('success', true, 'version_no', v_next);
END;
$$;

-- Actionable notifications helper
CREATE OR REPLACE FUNCTION employee_notify_actionable(
  p_employee_id uuid,
  p_title text,
  p_body text,
  p_type text,
  p_entity_type text DEFAULT NULL,
  p_entity_id uuid DEFAULT NULL
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO employee_notifications (
    employee_id, title, body, notification_type, related_entity_type, related_entity_id
  ) VALUES (p_employee_id, p_title, p_body, p_type, p_entity_type, p_entity_id);
END;
$$;
