-- Property Publishing & Field Data Operations
-- Extends Employee Portal with Publishing / Information / Photography / Engineering.
-- 8-digit Property ID is the central public key (unique constraint).

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ── Departments & permissions for publishing ops ────────────────────────────
INSERT INTO employee_departments (code, name_en, name_ar, name_ku)
SELECT * FROM (VALUES
  ('publishing', 'Publishing', 'النشر', 'بڵاوکردنەوە'),
  ('information', 'Property Information', 'معلومات العقار', 'زانیاری موڵک'),
  ('photography', 'Property Media', 'تصوير العقار', 'وێنەگرتنی موڵک'),
  ('engineering', 'Mapping / Engineering', 'الهندسة والمخططات', 'نەخشە / ئەندازیاری')
) AS v(code, name_en, name_ar, name_ku)
WHERE NOT EXISTS (
  SELECT 1 FROM employee_departments d WHERE d.code = v.code
);

INSERT INTO employee_permissions (code, description)
SELECT * FROM (VALUES
  ('publishing.view', 'View publishing pipeline'),
  ('publishing.create', 'Create publishing requests'),
  ('publishing.assign', 'Assign field staff'),
  ('publishing.edit', 'Edit publishing property content'),
  ('publishing.review', 'Review completeness'),
  ('publishing.publish', 'Publish / unpublish properties'),
  ('information.view', 'View information assignments'),
  ('information.edit', 'Edit field property intelligence report'),
  ('information.submit', 'Submit completed information report'),
  ('media.view', 'View media assignments'),
  ('media.upload', 'Upload photos / 3D captures'),
  ('media.submit', 'Submit media package'),
  ('engineering.view', 'View engineering assignments'),
  ('engineering.edit', 'Edit floor plans'),
  ('engineering.submit', 'Submit floor plans')
) AS v(code, description)
WHERE NOT EXISTS (
  SELECT 1 FROM employee_permissions p WHERE p.code = v.code
);

DO $$
DECLARE
  d_pub uuid; d_info uuid; d_photo uuid; d_eng uuid;
  r_id uuid;
BEGIN
  SELECT id INTO d_pub FROM employee_departments WHERE code = 'publishing';
  SELECT id INTO d_info FROM employee_departments WHERE code = 'information';
  SELECT id INTO d_photo FROM employee_departments WHERE code = 'photography';
  SELECT id INTO d_eng FROM employee_departments WHERE code = 'engineering';

  IF d_pub IS NOT NULL AND NOT EXISTS (SELECT 1 FROM employee_roles WHERE code = 'publishing_officer') THEN
    INSERT INTO employee_roles (department_id, code, name_en, name_ar)
    VALUES (d_pub, 'publishing_officer', 'Publishing Officer', 'موظف نشر')
    RETURNING id INTO r_id;
    INSERT INTO employee_role_permissions (role_id, permission_id)
    SELECT r_id, p.id FROM employee_permissions p
    WHERE p.code LIKE 'publishing.%'
       OR p.code IN ('properties.view','properties.assign','messages.view','messages.send','audit.view','search.global')
    ON CONFLICT DO NOTHING;
  END IF;

  IF d_info IS NOT NULL AND NOT EXISTS (SELECT 1 FROM employee_roles WHERE code = 'information_specialist') THEN
    INSERT INTO employee_roles (department_id, code, name_en, name_ar)
    VALUES (d_info, 'information_specialist', 'Information Specialist', 'أخصائي معلومات')
    RETURNING id INTO r_id;
    INSERT INTO employee_role_permissions (role_id, permission_id)
    SELECT r_id, p.id FROM employee_permissions p
    WHERE p.code LIKE 'information.%'
       OR p.code IN ('properties.view','messages.view','messages.send','search.global')
    ON CONFLICT DO NOTHING;
  END IF;

  IF d_photo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM employee_roles WHERE code = 'media_specialist') THEN
    INSERT INTO employee_roles (department_id, code, name_en, name_ar)
    VALUES (d_photo, 'media_specialist', 'Media Specialist', 'أخصائي تصوير')
    RETURNING id INTO r_id;
    INSERT INTO employee_role_permissions (role_id, permission_id)
    SELECT r_id, p.id FROM employee_permissions p
    WHERE p.code LIKE 'media.%'
       OR p.code IN ('properties.view','messages.view','messages.send','search.global')
    ON CONFLICT DO NOTHING;
  END IF;

  IF d_eng IS NOT NULL AND NOT EXISTS (SELECT 1 FROM employee_roles WHERE code = 'mapping_engineer') THEN
    INSERT INTO employee_roles (department_id, code, name_en, name_ar)
    VALUES (d_eng, 'mapping_engineer', 'Mapping Engineer', 'مهندس مخططات')
    RETURNING id INTO r_id;
    INSERT INTO employee_role_permissions (role_id, permission_id)
    SELECT r_id, p.id FROM employee_permissions p
    WHERE p.code LIKE 'engineering.%'
       OR p.code IN ('properties.view','messages.view','messages.send','search.global')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;

-- ── Central property catalog (8-digit public id) ────────────────────────────
CREATE TABLE IF NOT EXISTS property_assets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  public_property_id char(8) NOT NULL UNIQUE,
  -- Linked listing row when published into consumer catalog (optional)
  listing_property_id uuid,
  property_type text,
  transaction_type text,
  pipeline_status text NOT NULL DEFAULT 'request_created',
  -- request_created | assigned | information_collection | photography | three_d_capture
  -- | floor_plan | data_review | media_review | engineering_review
  -- | ready_for_publication | published
  -- exceptional: paused | rejected | needs_correction | owner_unavailable | cancelled | expired | unpublished | archived
  source text, -- office | company | owner | reporter
  owner_name text,
  owner_phone text,
  office_id uuid,
  reporter_label text,
  country_code text DEFAULT 'IQ',
  city text,
  province text,
  district text,
  neighborhood text,
  street text,
  address_text text,
  latitude double precision,
  longitude double precision,
  priority text DEFAULT 'normal',
  notes text,
  information_pct integer NOT NULL DEFAULT 0,
  photography_pct integer NOT NULL DEFAULT 0,
  three_d_pct integer NOT NULL DEFAULT 0,
  floor_plan_pct integer NOT NULL DEFAULT 0,
  quality_score numeric,
  is_published boolean NOT NULL DEFAULT false,
  published_at timestamptz,
  created_by_employee_id uuid REFERENCES employees(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_property_assets_status ON property_assets (pipeline_status);
CREATE INDEX IF NOT EXISTS idx_property_assets_office ON property_assets (office_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_property_assets_public_id ON property_assets (public_property_id);

CREATE TABLE IF NOT EXISTS property_publishing_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_asset_id uuid NOT NULL REFERENCES property_assets(id) ON DELETE CASCADE,
  request_number text NOT NULL UNIQUE,
  status text NOT NULL DEFAULT 'open',
  created_by_employee_id uuid REFERENCES employees(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS property_pipeline_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_asset_id uuid NOT NULL REFERENCES property_assets(id) ON DELETE CASCADE,
  event_type text NOT NULL,
  message text,
  actor_employee_id uuid REFERENCES employees(id),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pipeline_events_property
  ON property_pipeline_events (property_asset_id, created_at DESC);

CREATE TABLE IF NOT EXISTS employee_property_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_asset_id uuid NOT NULL REFERENCES property_assets(id) ON DELETE CASCADE,
  employee_id uuid NOT NULL REFERENCES employees(id),
  assignment_role text NOT NULL, -- information | photography | engineering | publishing
  status text NOT NULL DEFAULT 'assigned', -- assigned | in_progress | completed | returned
  assigned_by_employee_id uuid REFERENCES employees(id),
  assigned_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  UNIQUE (property_asset_id, employee_id, assignment_role)
);

CREATE TABLE IF NOT EXISTS field_visits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_asset_id uuid NOT NULL REFERENCES property_assets(id) ON DELETE CASCADE,
  employee_id uuid NOT NULL REFERENCES employees(id),
  visit_type text NOT NULL DEFAULT 'information', -- information | photography | engineering
  started_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz,
  start_latitude double precision,
  start_longitude double precision,
  notes text
);

-- ── Information domain (normalized + flexible jsonb) ────────────────────────
CREATE TABLE IF NOT EXISTS property_information (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_asset_id uuid NOT NULL UNIQUE REFERENCES property_assets(id) ON DELETE CASCADE,
  basic jsonb NOT NULL DEFAULT '{}'::jsonb,
  location jsonb NOT NULL DEFAULT '{}'::jsonb,
  dimensions jsonb NOT NULL DEFAULT '{}'::jsonb,
  land_shape text,
  structure jsonb NOT NULL DEFAULT '{}'::jsonb,
  kitchen jsonb NOT NULL DEFAULT '{}'::jsonb,
  exterior jsonb NOT NULL DEFAULT '{}'::jsonb,
  utilities jsonb NOT NULL DEFAULT '{}'::jsonb,
  construction jsonb NOT NULL DEFAULT '{}'::jsonb,
  orientation jsonb NOT NULL DEFAULT '{}'::jsonb,
  neighborhood jsonb NOT NULL DEFAULT '{}'::jsonb,
  investment jsonb NOT NULL DEFAULT '{}'::jsonb,
  condition jsonb NOT NULL DEFAULT '{}'::jsonb,
  field_notes text,
  required_completed integer NOT NULL DEFAULT 0,
  required_total integer NOT NULL DEFAULT 92,
  status text NOT NULL DEFAULT 'draft', -- draft | submitted | returned | approved
  submitted_at timestamptz,
  submitted_by_employee_id uuid REFERENCES employees(id),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS property_rooms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_asset_id uuid NOT NULL REFERENCES property_assets(id) ON DELETE CASCADE,
  room_type text NOT NULL,
  room_name text,
  floor_label text,
  length_m numeric,
  width_m numeric,
  height_m numeric,
  area_m2 numeric,
  windows_count integer,
  doors_count integer,
  flooring text,
  lighting text,
  condition text,
  orientation text,
  notes text,
  sort_order integer DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS property_bathrooms_detail (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_asset_id uuid NOT NULL REFERENCES property_assets(id) ON DELETE CASCADE,
  bathroom_number integer,
  length_m numeric,
  width_m numeric,
  area_m2 numeric,
  features jsonb NOT NULL DEFAULT '{}'::jsonb,
  condition text,
  notes text
);

CREATE TABLE IF NOT EXISTS property_nearby_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_asset_id uuid NOT NULL REFERENCES property_assets(id) ON DELETE CASCADE,
  place_type text NOT NULL,
  name text,
  distance_m numeric,
  walking_minutes integer,
  driving_minutes integer,
  notes text
);

-- ── Media / 3D ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS property_media_assets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_asset_id uuid NOT NULL REFERENCES property_assets(id) ON DELETE CASCADE,
  media_kind text NOT NULL DEFAULT 'photo', -- photo | video | document
  category text NOT NULL DEFAULT 'other',
  room_label text,
  sequence_no integer DEFAULT 0,
  storage_path text,
  media_url text,
  caption text,
  angle text,
  special_feature text,
  width_px integer,
  height_px integer,
  quality_flags jsonb NOT NULL DEFAULT '{}'::jsonb,
  uploaded_by_employee_id uuid REFERENCES employees(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_property_media_assets_property
  ON property_media_assets (property_asset_id, category, sequence_no);

CREATE TABLE IF NOT EXISTS property_3d_tours (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_asset_id uuid NOT NULL UNIQUE REFERENCES property_assets(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'draft',
  created_by_employee_id uuid REFERENCES employees(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS property_3d_capture_points (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tour_id uuid NOT NULL REFERENCES property_3d_tours(id) ON DELETE CASCADE,
  property_asset_id uuid NOT NULL REFERENCES property_assets(id) ON DELETE CASCADE,
  point_code text NOT NULL, -- POINT-001
  room_label text,
  position_label text,
  sequence_no integer DEFAULT 0,
  media_url text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE (tour_id, point_code)
);

CREATE TABLE IF NOT EXISTS property_3d_connections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tour_id uuid NOT NULL REFERENCES property_3d_tours(id) ON DELETE CASCADE,
  from_point_id uuid NOT NULL REFERENCES property_3d_capture_points(id) ON DELETE CASCADE,
  to_point_id uuid NOT NULL REFERENCES property_3d_capture_points(id) ON DELETE CASCADE
);

-- ── Floor plans / engineering ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS floor_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_asset_id uuid NOT NULL REFERENCES property_assets(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'draft', -- draft | submitted | needs_correction | approved
  scale text,
  north_direction text,
  measurement_unit text NOT NULL DEFAULT 'm',
  drawing_version integer NOT NULL DEFAULT 1,
  storage_path text,
  media_url text,
  created_by_employee_id uuid REFERENCES employees(id),
  reviewed_by_employee_id uuid REFERENCES employees(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS floor_plan_floors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  floor_plan_id uuid NOT NULL REFERENCES floor_plans(id) ON DELETE CASCADE,
  floor_key text NOT NULL, -- basement | ground | first | ... | roof
  floor_label text,
  sort_order integer DEFAULT 0,
  UNIQUE (floor_plan_id, floor_key)
);

CREATE TABLE IF NOT EXISTS floor_plan_rooms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  floor_id uuid NOT NULL REFERENCES floor_plan_floors(id) ON DELETE CASCADE,
  room_name text NOT NULL,
  length_m numeric,
  width_m numeric,
  height_m numeric,
  area_m2 numeric,
  custom_area boolean NOT NULL DEFAULT false,
  geometry jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS floor_plan_points (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  floor_id uuid NOT NULL REFERENCES floor_plan_floors(id) ON DELETE CASCADE,
  point_label text,
  room_name text,
  x_pct numeric,
  y_pct numeric,
  linked_3d_point_id uuid REFERENCES property_3d_capture_points(id),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);

-- ── Tags, translations, versioning, reviews ─────────────────────────────────
CREATE TABLE IF NOT EXISTS property_tags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_asset_id uuid NOT NULL REFERENCES property_assets(id) ON DELETE CASCADE,
  tag text NOT NULL,
  tag_group text DEFAULT 'feature', -- feature | search | neighborhood | investment
  UNIQUE (property_asset_id, tag, tag_group)
);

CREATE TABLE IF NOT EXISTS property_content_i18n (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_asset_id uuid NOT NULL REFERENCES property_assets(id) ON DELETE CASCADE,
  field_key text NOT NULL, -- description | title | highlights
  language_code text NOT NULL, -- ar | en | ku
  content text NOT NULL,
  is_original boolean NOT NULL DEFAULT false,
  translation_status text DEFAULT 'original', -- original | ai_draft | human_reviewed | approved
  UNIQUE (property_asset_id, field_key, language_code)
);

CREATE TABLE IF NOT EXISTS property_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_asset_id uuid NOT NULL REFERENCES property_assets(id) ON DELETE CASCADE,
  version_no integer NOT NULL,
  changed_by_employee_id uuid REFERENCES employees(id),
  changed_fields jsonb NOT NULL DEFAULT '[]'::jsonb,
  snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (property_asset_id, version_no)
);

CREATE TABLE IF NOT EXISTS publishing_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_asset_id uuid NOT NULL REFERENCES property_assets(id) ON DELETE CASCADE,
  checklist jsonb NOT NULL DEFAULT '{}'::jsonb,
  completeness_pct integer NOT NULL DEFAULT 0,
  decision text, -- approved | rejected | needs_correction
  notes text,
  reviewed_by_employee_id uuid REFERENCES employees(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ── ID generation ───────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION generate_public_property_id()
RETURNS char(8)
LANGUAGE plpgsql
AS $$
DECLARE
  v_id text;
  v_tries integer := 0;
BEGIN
  LOOP
    v_tries := v_tries + 1;
    -- 8-digit numeric, avoid leading zero for readability (1xxxxxxx)
    v_id := lpad((10000000 + floor(random() * 90000000)::bigint)::text, 8, '0');
    EXIT WHEN NOT EXISTS (
      SELECT 1 FROM property_assets WHERE public_property_id = v_id
    );
    IF v_tries > 40 THEN
      RAISE EXCEPTION 'unable_to_allocate_property_id';
    END IF;
  END LOOP;
  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION publishing_log_event(
  p_property_id uuid,
  p_event_type text,
  p_message text,
  p_employee_id uuid DEFAULT NULL,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO property_pipeline_events (
    property_asset_id, event_type, message, actor_employee_id, metadata
  ) VALUES (p_property_id, p_event_type, p_message, p_employee_id, p_metadata);
END;
$$;

-- ── Create publishing request + property id ─────────────────────────────────
CREATE OR REPLACE FUNCTION publishing_create_request(
  p_session_token text,
  p_property_type text,
  p_transaction_type text,
  p_source text,
  p_owner_name text,
  p_owner_phone text,
  p_office_id uuid DEFAULT NULL,
  p_reporter_label text DEFAULT NULL,
  p_city text DEFAULT NULL,
  p_address_text text DEFAULT NULL,
  p_latitude double precision DEFAULT NULL,
  p_longitude double precision DEFAULT NULL,
  p_notes text DEFAULT NULL,
  p_priority text DEFAULT 'normal',
  p_country_code text DEFAULT 'IQ'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_emp_id uuid;
  v_public_id char(8);
  v_asset_id uuid;
  v_req_id uuid;
  v_req_number text;
BEGIN
  v_emp_id := employee_session_employee_id(p_session_token);
  IF v_emp_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;
  IF NOT employee_has_permission(v_emp_id, 'publishing.create') THEN
    RETURN jsonb_build_object('success', false, 'message', 'forbidden');
  END IF;

  v_public_id := generate_public_property_id();

  INSERT INTO property_assets (
    public_property_id, property_type, transaction_type, pipeline_status,
    source, owner_name, owner_phone, office_id, reporter_label,
    country_code, city, address_text, latitude, longitude, notes, priority,
    created_by_employee_id
  ) VALUES (
    v_public_id, p_property_type, p_transaction_type, 'request_created',
    p_source, p_owner_name, p_owner_phone, p_office_id, p_reporter_label,
    p_country_code, p_city, p_address_text, p_latitude, p_longitude, p_notes, p_priority,
    v_emp_id
  ) RETURNING id INTO v_asset_id;

  v_req_number := 'PUB-' || to_char(now(), 'YYYYMMDD') || '-' || substr(v_public_id, 1, 4);
  INSERT INTO property_publishing_requests (
    property_asset_id, request_number, created_by_employee_id
  ) VALUES (v_asset_id, v_req_number, v_emp_id)
  RETURNING id INTO v_req_id;

  INSERT INTO property_information (property_asset_id) VALUES (v_asset_id);

  PERFORM publishing_log_event(
    v_asset_id, 'request_created',
    'Publishing request created. Property ID ' || v_public_id,
    v_emp_id,
    jsonb_build_object('request_id', v_req_id, 'public_property_id', v_public_id)
  );
  PERFORM employee_write_audit(
    v_emp_id, 'publishing.create_request', 'property_asset', v_asset_id::text,
    NULL, v_public_id, NULL, NULL
  );

  RETURN jsonb_build_object(
    'success', true,
    'property_asset_id', v_asset_id,
    'public_property_id', v_public_id,
    'request_id', v_req_id,
    'request_number', v_req_number
  );
END;
$$;

CREATE OR REPLACE FUNCTION publishing_assign_employee(
  p_session_token text,
  p_property_asset_id uuid,
  p_employee_id uuid,
  p_assignment_role text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_emp_id uuid;
  v_next_status text;
BEGIN
  v_emp_id := employee_session_employee_id(p_session_token);
  IF v_emp_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;
  IF NOT employee_has_permission(v_emp_id, 'publishing.assign') THEN
    RETURN jsonb_build_object('success', false, 'message', 'forbidden');
  END IF;

  INSERT INTO employee_property_assignments (
    property_asset_id, employee_id, assignment_role, assigned_by_employee_id
  ) VALUES (
    p_property_asset_id, p_employee_id, p_assignment_role, v_emp_id
  )
  ON CONFLICT (property_asset_id, employee_id, assignment_role)
  DO UPDATE SET status = 'assigned', assigned_at = now(), assigned_by_employee_id = v_emp_id;

  v_next_status := CASE p_assignment_role
    WHEN 'information' THEN 'information_collection'
    WHEN 'photography' THEN 'photography'
    WHEN 'engineering' THEN 'floor_plan'
    ELSE 'assigned'
  END;

  UPDATE property_assets
  SET pipeline_status = v_next_status, updated_at = now()
  WHERE id = p_property_asset_id;

  INSERT INTO employee_notifications (employee_id, title, body, notification_type, related_entity_type, related_entity_id)
  VALUES (
    p_employee_id,
    'New property assignment',
    'You were assigned as ' || p_assignment_role,
    'assignment',
    'property_asset',
    p_property_asset_id
  );

  PERFORM publishing_log_event(
    p_property_asset_id, 'assigned',
    'Assigned ' || p_assignment_role,
    v_emp_id,
    jsonb_build_object('assignee', p_employee_id, 'role', p_assignment_role)
  );

  RETURN jsonb_build_object('success', true, 'pipeline_status', v_next_status);
END;
$$;

CREATE OR REPLACE FUNCTION publishing_transition_status(
  p_session_token text,
  p_property_asset_id uuid,
  p_new_status text,
  p_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_emp_id uuid;
  v_old text;
BEGIN
  v_emp_id := employee_session_employee_id(p_session_token);
  IF v_emp_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;
  IF NOT (
    employee_has_permission(v_emp_id, 'publishing.edit')
    OR employee_has_permission(v_emp_id, 'publishing.review')
    OR employee_has_permission(v_emp_id, 'publishing.publish')
  ) THEN
    RETURN jsonb_build_object('success', false, 'message', 'forbidden');
  END IF;

  SELECT pipeline_status INTO v_old FROM property_assets WHERE id = p_property_asset_id;
  IF v_old IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'not_found');
  END IF;

  UPDATE property_assets
  SET pipeline_status = p_new_status,
      is_published = CASE WHEN p_new_status = 'published' THEN true ELSE is_published END,
      published_at = CASE WHEN p_new_status = 'published' THEN now() ELSE published_at END,
      updated_at = now()
  WHERE id = p_property_asset_id;

  PERFORM publishing_log_event(
    p_property_asset_id, 'status_change',
    coalesce(p_reason, 'Status → ' || p_new_status),
    v_emp_id,
    jsonb_build_object('from', v_old, 'to', p_new_status)
  );
  PERFORM employee_write_audit(
    v_emp_id, 'publishing.status_change', 'property_asset', p_property_asset_id::text,
    v_old, p_new_status, p_reason, NULL
  );

  RETURN jsonb_build_object('success', true, 'pipeline_status', p_new_status);
END;
$$;

CREATE OR REPLACE FUNCTION information_submit_report(
  p_session_token text,
  p_property_asset_id uuid,
  p_required_completed integer,
  p_required_total integer DEFAULT 92
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_emp_id uuid;
  v_pct integer;
BEGIN
  v_emp_id := employee_session_employee_id(p_session_token);
  IF v_emp_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;
  IF NOT employee_has_permission(v_emp_id, 'information.submit') THEN
    RETURN jsonb_build_object('success', false, 'message', 'forbidden');
  END IF;
  IF p_required_completed < p_required_total THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'incomplete',
      'required_completed', p_required_completed,
      'required_total', p_required_total
    );
  END IF;

  v_pct := least(100, (p_required_completed * 100) / greatest(p_required_total, 1));

  UPDATE property_information
  SET status = 'submitted',
      required_completed = p_required_completed,
      required_total = p_required_total,
      submitted_at = now(),
      submitted_by_employee_id = v_emp_id,
      updated_at = now()
  WHERE property_asset_id = p_property_asset_id;

  UPDATE property_assets
  SET information_pct = v_pct,
      pipeline_status = 'photography',
      updated_at = now()
  WHERE id = p_property_asset_id;

  UPDATE employee_property_assignments
  SET status = 'completed', completed_at = now()
  WHERE property_asset_id = p_property_asset_id
    AND employee_id = v_emp_id
    AND assignment_role = 'information';

  PERFORM publishing_log_event(
    p_property_asset_id, 'information_completed',
    'Information report submitted',
    v_emp_id,
    jsonb_build_object('pct', v_pct)
  );

  RETURN jsonb_build_object('success', true, 'information_pct', v_pct);
END;
$$;

CREATE OR REPLACE FUNCTION media_submit_package(
  p_session_token text,
  p_property_asset_id uuid,
  p_photo_count integer,
  p_three_d_points integer DEFAULT 0
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_emp_id uuid;
  v_photo_pct integer;
  v_3d_pct integer;
BEGIN
  v_emp_id := employee_session_employee_id(p_session_token);
  IF v_emp_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;
  IF NOT employee_has_permission(v_emp_id, 'media.submit') THEN
    RETURN jsonb_build_object('success', false, 'message', 'forbidden');
  END IF;

  v_photo_pct := least(100, (p_photo_count * 100) / 18);
  v_3d_pct := least(100, (p_three_d_points * 100) / 4);

  UPDATE property_assets
  SET photography_pct = v_photo_pct,
      three_d_pct = v_3d_pct,
      pipeline_status = CASE
        WHEN v_3d_pct >= 100 THEN 'floor_plan'
        ELSE 'three_d_capture'
      END,
      updated_at = now()
  WHERE id = p_property_asset_id;

  UPDATE employee_property_assignments
  SET status = 'completed', completed_at = now()
  WHERE property_asset_id = p_property_asset_id
    AND employee_id = v_emp_id
    AND assignment_role = 'photography';

  PERFORM publishing_log_event(
    p_property_asset_id, 'media_completed',
    'Media package submitted',
    v_emp_id,
    jsonb_build_object('photos', p_photo_count, 'points', p_three_d_points)
  );

  RETURN jsonb_build_object(
    'success', true,
    'photography_pct', v_photo_pct,
    'three_d_pct', v_3d_pct
  );
END;
$$;

CREATE OR REPLACE FUNCTION engineering_submit_floor_plan(
  p_session_token text,
  p_floor_plan_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_emp_id uuid;
  v_asset uuid;
  v_floors integer;
  v_rooms integer;
BEGIN
  v_emp_id := employee_session_employee_id(p_session_token);
  IF v_emp_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;
  IF NOT employee_has_permission(v_emp_id, 'engineering.submit') THEN
    RETURN jsonb_build_object('success', false, 'message', 'forbidden');
  END IF;

  SELECT property_asset_id INTO v_asset FROM floor_plans WHERE id = p_floor_plan_id;
  IF v_asset IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'not_found');
  END IF;

  SELECT COUNT(*) INTO v_floors FROM floor_plan_floors WHERE floor_plan_id = p_floor_plan_id;
  SELECT COUNT(*) INTO v_rooms
  FROM floor_plan_rooms r
  JOIN floor_plan_floors f ON f.id = r.floor_id
  WHERE f.floor_plan_id = p_floor_plan_id;

  IF v_floors < 1 OR v_rooms < 1 THEN
    RETURN jsonb_build_object('success', false, 'message', 'incomplete_floor_plan');
  END IF;

  UPDATE floor_plans
  SET status = 'submitted', updated_at = now()
  WHERE id = p_floor_plan_id;

  UPDATE property_assets
  SET floor_plan_pct = 100,
      pipeline_status = 'data_review',
      updated_at = now()
  WHERE id = v_asset;

  UPDATE employee_property_assignments
  SET status = 'completed', completed_at = now()
  WHERE property_asset_id = v_asset
    AND employee_id = v_emp_id
    AND assignment_role = 'engineering';

  PERFORM publishing_log_event(
    v_asset, 'floor_plan_submitted',
    'Floor plan submitted',
    v_emp_id,
    jsonb_build_object('floors', v_floors, 'rooms', v_rooms)
  );

  RETURN jsonb_build_object('success', true, 'floors', v_floors, 'rooms', v_rooms);
END;
$$;

CREATE OR REPLACE FUNCTION publishing_final_publish(
  p_session_token text,
  p_property_asset_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_emp_id uuid;
  v_row property_assets%ROWTYPE;
BEGIN
  v_emp_id := employee_session_employee_id(p_session_token);
  IF v_emp_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'unauthorized');
  END IF;
  IF NOT employee_has_permission(v_emp_id, 'publishing.publish') THEN
    RETURN jsonb_build_object('success', false, 'message', 'forbidden');
  END IF;

  SELECT * INTO v_row FROM property_assets WHERE id = p_property_asset_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'not_found');
  END IF;

  IF v_row.information_pct < 100 OR v_row.photography_pct < 80
     OR v_row.three_d_pct < 50 OR v_row.floor_plan_pct < 100 THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'incomplete_requirements',
      'information_pct', v_row.information_pct,
      'photography_pct', v_row.photography_pct,
      'three_d_pct', v_row.three_d_pct,
      'floor_plan_pct', v_row.floor_plan_pct
    );
  END IF;

  UPDATE property_assets
  SET pipeline_status = 'published',
      is_published = true,
      published_at = now(),
      updated_at = now()
  WHERE id = p_property_asset_id;

  INSERT INTO publishing_reviews (
    property_asset_id, checklist, completeness_pct, decision, reviewed_by_employee_id
  ) VALUES (
    p_property_asset_id,
    jsonb_build_object(
      'information', true,
      'media', true,
      'three_d', true,
      'floor_plan', true
    ),
    100,
    'approved',
    v_emp_id
  );

  PERFORM publishing_log_event(
    p_property_asset_id, 'published',
    'Property published',
    v_emp_id,
    jsonb_build_object('public_property_id', v_row.public_property_id)
  );
  PERFORM employee_write_audit(
    v_emp_id, 'publishing.publish', 'property_asset', p_property_asset_id::text,
    NULL, v_row.public_property_id, NULL, NULL
  );

  RETURN jsonb_build_object(
    'success', true,
    'public_property_id', v_row.public_property_id,
    'pipeline_status', 'published'
  );
END;
$$;

COMMENT ON TABLE property_assets IS 'Central publishing catalog; public_property_id is the 8-digit twin key.';
COMMENT ON COLUMN property_assets.public_property_id IS 'Globally unique 8-digit Property ID.';
COMMENT ON FUNCTION publishing_create_request IS 'Creates property asset + publishing request with unique 8-digit ID.';
