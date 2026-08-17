-- Property map & search performance indexes
CREATE INDEX IF NOT EXISTS idx_properties_v3_lat_lng
  ON properties_v3 (latitude, longitude);

CREATE INDEX IF NOT EXISTS idx_properties_v3_listing_type
  ON properties_v3 (listing_type);

CREATE INDEX IF NOT EXISTS idx_properties_v3_property_type
  ON properties_v3 (property_type);

CREATE INDEX IF NOT EXISTS idx_properties_v3_country_code
  ON properties_v3 (country_code);

CREATE INDEX IF NOT EXISTS idx_properties_v3_asking_price
  ON properties_v3 (asking_price);

CREATE INDEX IF NOT EXISTS idx_properties_v3_area
  ON properties_v3 (total_area_sqm);

CREATE INDEX IF NOT EXISTS idx_properties_v3_status_created
  ON properties_v3 (listing_status, created_at DESC);

-- Composite for common map bounds + filter queries
CREATE INDEX IF NOT EXISTS idx_properties_v3_map_query
  ON properties_v3 (country_code, listing_type, latitude, longitude);

-- Optional PostGIS (enable extension in Supabase dashboard first):
-- CREATE EXTENSION IF NOT EXISTS postgis;
-- ALTER TABLE properties_v3 ADD COLUMN IF NOT EXISTS geom geography(POINT, 4326);
-- UPDATE properties_v3 SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
--   WHERE latitude IS NOT NULL AND longitude IS NOT NULL AND geom IS NULL;
-- CREATE INDEX IF NOT EXISTS idx_properties_v3_geom ON properties_v3 USING GIST (geom);
