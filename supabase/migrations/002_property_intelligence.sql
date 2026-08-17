-- Property Intelligence Domain
-- Extends properties_v3 with flexible JSONB + historical/relational tables.
-- Safe to run multiple times (IF NOT EXISTS). Does not invent data.

CREATE EXTENSION IF NOT EXISTS postgis;

-- ── Core property flexibility (publisher-controlled) ───────────────────────
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'properties_v3'
  ) THEN
    ALTER TABLE properties_v3
      ADD COLUMN IF NOT EXISTS areas jsonb DEFAULT '{}'::jsonb,
      ADD COLUMN IF NOT EXISTS interior_features jsonb DEFAULT '{}'::jsonb,
      ADD COLUMN IF NOT EXISTS exterior_features jsonb DEFAULT '{}'::jsonb,
      ADD COLUMN IF NOT EXISTS utilities jsonb DEFAULT '{}'::jsonb,
      ADD COLUMN IF NOT EXISTS energy jsonb DEFAULT '{}'::jsonb,
      ADD COLUMN IF NOT EXISTS building_details jsonb DEFAULT '{}'::jsonb,
      ADD COLUMN IF NOT EXISTS renovation jsonb DEFAULT '{}'::jsonb,
      ADD COLUMN IF NOT EXISTS development_potential jsonb DEFAULT '{}'::jsonb,
      ADD COLUMN IF NOT EXISTS whats_special jsonb DEFAULT '{}'::jsonb,
      ADD COLUMN IF NOT EXISTS rent_to_own jsonb DEFAULT '{}'::jsonb,
      ADD COLUMN IF NOT EXISTS investment jsonb DEFAULT '{}'::jsonb,
      ADD COLUMN IF NOT EXISTS rental jsonb DEFAULT '{}'::jsonb,
      ADD COLUMN IF NOT EXISTS history jsonb DEFAULT '{}'::jsonb,
      ADD COLUMN IF NOT EXISTS surroundings jsonb DEFAULT '{}'::jsonb,
      ADD COLUMN IF NOT EXISTS intelligence jsonb DEFAULT '{}'::jsonb,
      ADD COLUMN IF NOT EXISTS previous_price numeric,
      ADD COLUMN IF NOT EXISTS estimated_value numeric,
      ADD COLUMN IF NOT EXISTS price_change_percent numeric,
      ADD COLUMN IF NOT EXISTS neighborhood text,
      ADD COLUMN IF NOT EXISTS street text,
      ADD COLUMN IF NOT EXISTS postal_code text,
      ADD COLUMN IF NOT EXISTS living_rooms integer,
      ADD COLUMN IF NOT EXISTS parking_spaces integer,
      ADD COLUMN IF NOT EXISTS year_renovated integer,
      ADD COLUMN IF NOT EXISTS orientation text,
      ADD COLUMN IF NOT EXISTS has_elevator boolean,
      ADD COLUMN IF NOT EXISTS is_furnished boolean,
      ADD COLUMN IF NOT EXISTS has_balcony boolean,
      ADD COLUMN IF NOT EXISTS has_garden boolean,
      ADD COLUMN IF NOT EXISTS has_pool boolean,
      ADD COLUMN IF NOT EXISTS building_type text,
      ADD COLUMN IF NOT EXISTS unit_type text,
      ADD COLUMN IF NOT EXISTS country_name text;
  END IF;
END $$;

-- ── Media enrichment ────────────────────────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'property_media_v3'
  ) THEN
    ALTER TABLE property_media_v3
      ADD COLUMN IF NOT EXISTS media_type text DEFAULT 'photo',
      ADD COLUMN IF NOT EXISTS category text DEFAULT 'other',
      ADD COLUMN IF NOT EXISTS caption text,
      ADD COLUMN IF NOT EXISTS sort_order integer DEFAULT 0,
      ADD COLUMN IF NOT EXISTS thumbnail_url text,
      ADD COLUMN IF NOT EXISTS external_provider text,
      ADD COLUMN IF NOT EXISTS external_id text,
      ADD COLUMN IF NOT EXISTS room_key text;
  END IF;
END $$;

-- ── Price history (append-only) ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS property_price_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id uuid NOT NULL,
  effective_date timestamptz NOT NULL DEFAULT now(),
  price numeric NOT NULL,
  currency text NOT NULL DEFAULT 'USD',
  previous_price numeric,
  change_percent numeric,
  reason text,
  provenance text NOT NULL DEFAULT 'publisher_provided',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_property_price_history_property
  ON property_price_history (property_id, effective_date DESC);

-- ── Tax history ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS property_tax_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id uuid NOT NULL,
  tax_year integer NOT NULL,
  assessed_value numeric,
  tax_amount numeric,
  currency text NOT NULL DEFAULT 'USD',
  notes text,
  provenance text NOT NULL DEFAULT 'external',
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (property_id, tax_year)
);

-- ── Sales history (official when available) ─────────────────────────────────
CREATE TABLE IF NOT EXISTS property_sales_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id uuid NOT NULL,
  sold_at timestamptz NOT NULL,
  sale_price numeric NOT NULL,
  currency text NOT NULL DEFAULT 'USD',
  transaction_type text,
  source_name text,
  provenance text NOT NULL DEFAULT 'external',
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ── Future / nearby projects ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS property_future_projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id uuid,
  name text NOT NULL,
  project_type text,
  location_label text,
  distance_meters numeric,
  status text,
  expected_completion date,
  developer text,
  estimated_impact text DEFAULT 'unknown',
  description text,
  images jsonb DEFAULT '[]'::jsonb,
  source text,
  is_investment_opportunity boolean DEFAULT false,
  provenance text NOT NULL DEFAULT 'publisher_provided',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_property_future_projects_property
  ON property_future_projects (property_id);

-- ── Nearby places cache ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS property_nearby_places (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id uuid NOT NULL,
  name text NOT NULL,
  category text NOT NULL,
  subtype text,
  distance_meters numeric,
  travel_time_minutes integer,
  rating numeric,
  is_public boolean,
  provenance text NOT NULL DEFAULT 'external',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_property_nearby_places_property
  ON property_nearby_places (property_id, category);

-- ── Documents metadata (sensitive by default) ───────────────────────────────
CREATE TABLE IF NOT EXISTS property_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id uuid NOT NULL,
  title text NOT NULL,
  document_type text NOT NULL,
  storage_path text,
  url text,
  is_sensitive boolean NOT NULL DEFAULT true,
  provenance text NOT NULL DEFAULT 'publisher_provided',
  uploaded_at timestamptz NOT NULL DEFAULT now()
);

-- ── Sales inquiries (User → Sales Team, NOT agent) ──────────────────────────
CREATE TABLE IF NOT EXISTS property_inquiries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  property_id uuid NOT NULL,
  inquiry_type text NOT NULL DEFAULT 'sales',
  message text,
  status text NOT NULL DEFAULT 'new',
  assigned_team text NOT NULL DEFAULT 'sales',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_property_inquiries_property
  ON property_inquiries (property_id, created_at DESC);

-- ── Tour requests ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS property_tour_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  property_id uuid NOT NULL,
  tour_type text NOT NULL DEFAULT 'inPerson',
  preferred_date timestamptz,
  preferred_time text,
  notes text,
  status text NOT NULL DEFAULT 'new',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_property_tour_requests_property
  ON property_tour_requests (property_id, created_at DESC);

-- ── Internal analytics (separate from user-facing report) ───────────────────
CREATE TABLE IF NOT EXISTS property_analytics_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id uuid NOT NULL,
  user_id uuid,
  event_type text NOT NULL,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_property_analytics_events_property
  ON property_analytics_events (property_id, event_type, created_at DESC);

-- ── Saved-property notification hooks (engine later) ────────────────────────
CREATE TABLE IF NOT EXISTS property_watch_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  property_id uuid NOT NULL,
  notify_price_drop boolean DEFAULT true,
  notify_price_increase boolean DEFAULT false,
  notify_status_change boolean DEFAULT true,
  notify_new_photos boolean DEFAULT true,
  notify_new_info boolean DEFAULT true,
  notify_rent_to_own boolean DEFAULT true,
  notify_availability boolean DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, property_id)
);

COMMENT ON TABLE property_price_history IS
  'Append-only price changes; never overwrite current price without inserting history.';
COMMENT ON TABLE property_inquiries IS
  'Routes to Sales Team only — agents do not receive direct user messages.';
COMMENT ON COLUMN properties_v3.intelligence IS
  'Flexible publisher-controlled intelligence payload for future fields.';
