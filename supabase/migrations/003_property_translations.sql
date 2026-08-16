-- Property AI Translation cache + content language metadata
-- Versioned so publisher edits invalidate stale translations.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'properties_v3'
  ) THEN
    ALTER TABLE properties_v3
      ADD COLUMN IF NOT EXISTS original_language text,
      ADD COLUMN IF NOT EXISTS content_version text DEFAULT '1';
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS property_translations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id uuid NOT NULL,
  original_language text NOT NULL,
  target_language text NOT NULL,
  source_content_version text NOT NULL,
  translation_version text NOT NULL,
  original_content jsonb NOT NULL DEFAULT '{}'::jsonb,
  translated_content jsonb NOT NULL DEFAULT '{}'::jsonb,
  provider text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (property_id, target_language, source_content_version)
);

CREATE INDEX IF NOT EXISTS idx_property_translations_lookup
  ON property_translations (property_id, target_language, source_content_version);

COMMENT ON TABLE property_translations IS
  'AI property translation cache. Invalid when source_content_version mismatches property content_version.';
COMMENT ON COLUMN property_translations.original_content IS
  'Snapshot of source fields — originals are never overwritten on the property row.';
COMMENT ON COLUMN property_translations.translated_content IS
  'AI-generated translation of human-readable fields only.';
