-- 009: Complete remaining employee roles + HR bootstrap password + SMS audit
-- NOTE: HR-001 temporary secret is set here at operator request for private-repo bootstrap.
-- Rotate immediately in production via hr_set_employee_secret / change-password flow.

UPDATE employees
SET
  secret_hash = crypt('200611', gen_salt('bf')),
  must_change_password = true,
  temporary_secret_issued_at = now(),
  updated_at = now()
WHERE employee_code = 'HR-001';

-- ── Quality reviews ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS property_quality_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_asset_id uuid NOT NULL REFERENCES property_assets(id) ON DELETE CASCADE,
  reviewer_employee_id uuid REFERENCES employees(id),
  decision text, -- approve | reject | request_correction
  checklist jsonb NOT NULL DEFAULT '{}'::jsonb,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS compliance_cases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_code text NOT NULL UNIQUE,
  subject text NOT NULL,
  status text NOT NULL DEFAULT 'open', -- open | reviewing | escalated | cleared | blocked
  related_entity_type text,
  related_entity_id uuid,
  risk_level text DEFAULT 'medium',
  assigned_employee_id uuid REFERENCES employees(id),
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS system_config (
  key text PRIMARY KEY,
  value jsonb NOT NULL DEFAULT '{}'::jsonb,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by_employee_id uuid REFERENCES employees(id)
);

INSERT INTO system_config (key, value)
VALUES
  ('twilio.verify', jsonb_build_object(
    'friendly_name', 'Madar Verify',
    'service_sid', NULL,
    'enabled', false
  )),
  ('platform.features', jsonb_build_object(
    'sms_otp', true,
    'employee_2fa', true
  ))
ON CONFLICT (key) DO NOTHING;

CREATE TABLE IF NOT EXISTS sms_verification_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_e164 text NOT NULL,
  purpose text NOT NULL, -- employee_2fa | bank_buyer | user_auth | generic
  provider text NOT NULL DEFAULT 'twilio_verify',
  provider_sid text,
  status text NOT NULL DEFAULT 'pending', -- pending | sent | approved | failed
  related_entity_type text,
  related_entity_id uuid,
  requested_by_employee_id uuid REFERENCES employees(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  checked_at timestamptz
);

-- Closing case RPC
CREATE OR REPLACE FUNCTION closing_create_case(
  p_session_token text,
  p_buyer_name text,
  p_seller_name text,
  p_property_ref text,
  p_price_text text DEFAULT NULL,
  p_lead_id uuid DEFAULT NULL,
  p_office_id uuid DEFAULT NULL,
  p_sales_employee_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_emp_id uuid;
  v_id uuid;
  v_code text;
BEGIN
  v_emp_id := employee_session_employee_id(p_session_token);
  IF v_emp_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;
  IF NOT (
    employee_has_permission(v_emp_id, 'closing.manage')
    OR employee_has_permission(v_emp_id, 'sales.handoff')
  ) THEN
    RETURN jsonb_build_object('success', false, 'message', 'forbidden');
  END IF;

  v_code := 'CLOSE-' || to_char(now(), 'YYMMDD') || '-' ||
            lpad((floor(random()*9999))::int::text, 4, '0');
  INSERT INTO closing_cases (
    case_code, lead_id, buyer_name, seller_name, property_ref, price_text,
    office_id, sales_employee_id, closing_employee_id, status
  ) VALUES (
    v_code, p_lead_id, trim(p_buyer_name), trim(p_seller_name), p_property_ref,
    p_price_text, p_office_id, COALESCE(p_sales_employee_id, v_emp_id),
    CASE WHEN employee_has_permission(v_emp_id, 'closing.manage') THEN v_emp_id ELSE NULL END,
    'intake'
  ) RETURNING id INTO v_id;

  RETURN jsonb_build_object('success', true, 'case_id', v_id, 'case_code', v_code);
END;
$$;

CREATE OR REPLACE FUNCTION support_create_ticket(
  p_session_token text,
  p_subject text,
  p_priority text DEFAULT 'normal',
  p_related_entity_type text DEFAULT NULL,
  p_related_entity_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_emp_id uuid;
  v_id uuid;
  v_code text;
BEGIN
  v_emp_id := employee_session_employee_id(p_session_token);
  IF v_emp_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;
  IF NOT employee_has_permission(v_emp_id, 'support.tickets') THEN
    RETURN jsonb_build_object('success', false, 'message', 'forbidden');
  END IF;

  v_code := 'TKT-' || to_char(now(), 'YYMMDD') || '-' ||
            lpad((floor(random()*9999))::int::text, 4, '0');
  INSERT INTO support_tickets (
    ticket_code, subject, priority, status, assigned_employee_id,
    related_entity_type, related_entity_id
  ) VALUES (
    v_code, trim(p_subject), COALESCE(p_priority, 'normal'), 'open', v_emp_id,
    p_related_entity_type, p_related_entity_id
  ) RETURNING id INTO v_id;

  RETURN jsonb_build_object('success', true, 'ticket_id', v_id, 'ticket_code', v_code);
END;
$$;

CREATE OR REPLACE FUNCTION quality_submit_review(
  p_session_token text,
  p_property_asset_id uuid,
  p_decision text,
  p_checklist jsonb DEFAULT '{}'::jsonb,
  p_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_emp_id uuid;
BEGIN
  v_emp_id := employee_session_employee_id(p_session_token);
  IF v_emp_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;
  IF NOT employee_has_permission(v_emp_id, 'quality.review') THEN
    RETURN jsonb_build_object('success', false, 'message', 'forbidden');
  END IF;
  IF p_decision NOT IN ('approve', 'reject', 'request_correction') THEN
    RETURN jsonb_build_object('success', false, 'message', 'invalid_decision');
  END IF;

  INSERT INTO property_quality_reviews (
    property_asset_id, reviewer_employee_id, decision, checklist, notes
  ) VALUES (
    p_property_asset_id, v_emp_id, p_decision, COALESCE(p_checklist, '{}'::jsonb), p_notes
  );

  IF p_decision = 'approve' THEN
    PERFORM publishing_transition_status(
      p_session_token, p_property_asset_id, 'ready_for_publication', 'quality_approved'
    );
  ELSIF p_decision = 'request_correction' THEN
    PERFORM publishing_transition_status(
      p_session_token, p_property_asset_id, 'needs_correction', 'quality_correction'
    );
  ELSIF p_decision = 'reject' THEN
    PERFORM publishing_transition_status(
      p_session_token, p_property_asset_id, 'rejected', 'quality_rejected'
    );
  END IF;

  RETURN jsonb_build_object('success', true);
END;
$$;

CREATE OR REPLACE FUNCTION compliance_create_case(
  p_session_token text,
  p_subject text,
  p_risk_level text DEFAULT 'medium',
  p_related_entity_type text DEFAULT NULL,
  p_related_entity_id uuid DEFAULT NULL,
  p_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_emp_id uuid;
  v_id uuid;
  v_code text;
BEGIN
  v_emp_id := employee_session_employee_id(p_session_token);
  IF v_emp_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;
  IF NOT employee_has_permission(v_emp_id, 'compliance.review') THEN
    RETURN jsonb_build_object('success', false, 'message', 'forbidden');
  END IF;

  v_code := 'COMP-' || to_char(now(), 'YYMMDD') || '-' ||
            lpad((floor(random()*9999))::int::text, 4, '0');
  INSERT INTO compliance_cases (
    case_code, subject, risk_level, related_entity_type, related_entity_id,
    assigned_employee_id, notes, status
  ) VALUES (
    v_code, trim(p_subject), COALESCE(p_risk_level, 'medium'),
    p_related_entity_type, p_related_entity_id, v_emp_id, p_notes, 'open'
  ) RETURNING id INTO v_id;

  RETURN jsonb_build_object('success', true, 'case_id', v_id, 'case_code', v_code);
END;
$$;

CREATE OR REPLACE FUNCTION sms_log_verification(
  p_phone_e164 text,
  p_purpose text,
  p_provider_sid text DEFAULT NULL,
  p_status text DEFAULT 'sent',
  p_related_entity_type text DEFAULT NULL,
  p_related_entity_id uuid DEFAULT NULL,
  p_employee_id uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_id uuid;
BEGIN
  INSERT INTO sms_verification_logs (
    phone_e164, purpose, provider_sid, status,
    related_entity_type, related_entity_id, requested_by_employee_id
  ) VALUES (
    p_phone_e164, p_purpose, p_provider_sid, p_status,
    p_related_entity_type, p_related_entity_id, p_employee_id
  ) RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;

-- Stop returning debug OTP when Twilio delivery is expected (lab flag via config)
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
  v_sms_enabled boolean;
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

  SELECT COALESCE((value->>'enabled')::boolean, false)
  INTO v_sms_enabled
  FROM system_config WHERE key = 'twilio.verify';

  v_masked := '**' || right(v_phone, 4);
  RETURN jsonb_build_object(
    'success', true,
    'phone_masked', v_masked,
    'phone_e164', v_phone,
    'expires_in_seconds', 600,
    'delivery', CASE WHEN v_sms_enabled THEN 'twilio_verify' ELSE 'queued' END,
    -- Lab fallback only when Twilio Verify is not enabled.
    'debug_otp', CASE WHEN v_sms_enabled THEN NULL ELSE v_otp END
  );
END;
$$;

-- After Twilio Verify Check = approved, bank employee marks buyer verified.
CREATE OR REPLACE FUNCTION bank_mark_buyer_verified_via_twilio(
  p_session_token text,
  p_transaction_id uuid
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

  UPDATE bank_buyer_otps SET verified_at = now() WHERE id = v_row.id;
  PERFORM employee_write_audit(
    v_emp_id, 'bank.otp_verified_twilio', 'transaction', p_transaction_id::text
  );
  RETURN jsonb_build_object('success', true);
END;
$$;

CREATE OR REPLACE FUNCTION system_set_twilio_enabled(
  p_session_token text,
  p_enabled boolean,
  p_service_sid text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_emp_id uuid;
  v_val jsonb;
BEGIN
  v_emp_id := employee_session_employee_id(p_session_token);
  IF v_emp_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;
  IF NOT employee_has_permission(v_emp_id, 'system.config') THEN
    RETURN jsonb_build_object('success', false, 'message', 'forbidden');
  END IF;

  v_val := jsonb_build_object(
    'friendly_name', 'Madar Verify',
    'enabled', p_enabled,
    'service_sid', p_service_sid
  );
  INSERT INTO system_config (key, value, updated_at, updated_by_employee_id)
  VALUES ('twilio.verify', v_val, now(), v_emp_id)
  ON CONFLICT (key) DO UPDATE SET
    value = EXCLUDED.value,
    updated_at = now(),
    updated_by_employee_id = v_emp_id;

  RETURN jsonb_build_object('success', true, 'value', v_val);
END;
$$;
