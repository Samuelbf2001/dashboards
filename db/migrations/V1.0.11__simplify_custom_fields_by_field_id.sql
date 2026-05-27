-- ─────────────────────────────────────────────────────────────────────────────
-- V1.0.11 — Simplificar custom fields: usar field_id directo (sin capa canónica)
--
-- Elimina ghl_custom_field_defs y ghl_custom_field_map (innecesarias).
-- Recrea fact_contact_custom_fields y fact_opp_custom_fields usando el
-- field_id de GHL directamente como clave (ej: QlhDb5nIAcPexpGh4Gw5).
--
-- Cada dashboard clonado por cliente referencia los field_ids de esa location.
-- No se necesita lookup en webhooks — se extrae id+value del payload directo.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Limpiar esquema anterior (V1.0.8 / V1.0.9) ────────────────────────────
DROP TABLE IF EXISTS fact_contact_custom_fields CASCADE;
DROP TABLE IF EXISTS fact_opp_custom_fields     CASCADE;
DROP TABLE IF EXISTS ghl_custom_field_map       CASCADE;
DROP TABLE IF EXISTS ghl_custom_field_defs      CASCADE;


-- ── 2. fact_contact_custom_fields ────────────────────────────────────────────
CREATE TABLE fact_contact_custom_fields (
  contact_id   VARCHAR(50)   NOT NULL,
  location_id  VARCHAR(50)   NOT NULL,
  field_id     VARCHAR(100)  NOT NULL,
  value_text   TEXT,
  value_number NUMERIC(20,4),
  value_date   DATE,
  value_bool   BOOLEAN,
  updated_at   TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  PRIMARY KEY (contact_id, field_id)
);

COMMENT ON TABLE  fact_contact_custom_fields IS
  'Custom fields de contactos indexados por field_id de GHL. '
  'PK: (contact_id, field_id). Consultar con WHERE field_id = ''<id_de_la_location>''.';
COMMENT ON COLUMN fact_contact_custom_fields.field_id IS
  'ID único del custom field en la sub-cuenta GHL (ej: QlhDb5nIAcPexpGh4Gw5).';

CREATE INDEX idx_cf_contact_location  ON fact_contact_custom_fields(location_id);
CREATE INDEX idx_cf_contact_field     ON fact_contact_custom_fields(field_id);
CREATE INDEX idx_cf_contact_loc_field ON fact_contact_custom_fields(location_id, field_id);


-- ── 3. fact_opp_custom_fields ─────────────────────────────────────────────────
CREATE TABLE fact_opp_custom_fields (
  opportunity_id VARCHAR(50)   NOT NULL,
  location_id    VARCHAR(50)   NOT NULL,
  field_id       VARCHAR(100)  NOT NULL,
  value_text     TEXT,
  value_number   NUMERIC(20,4),
  value_date     DATE,
  value_bool     BOOLEAN,
  updated_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  PRIMARY KEY (opportunity_id, field_id)
);

COMMENT ON TABLE  fact_opp_custom_fields IS
  'Custom fields de oportunidades indexados por field_id de GHL.';
COMMENT ON COLUMN fact_opp_custom_fields.field_id IS
  'ID único del custom field en la sub-cuenta GHL.';

CREATE INDEX idx_cf_opp_location  ON fact_opp_custom_fields(location_id);
CREATE INDEX idx_cf_opp_field     ON fact_opp_custom_fields(field_id);
CREATE INDEX idx_cf_opp_loc_field ON fact_opp_custom_fields(location_id, field_id);


-- ── 4. RLS ────────────────────────────────────────────────────────────────────
ALTER TABLE fact_contact_custom_fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE fact_contact_custom_fields FORCE  ROW LEVEL SECURITY;
ALTER TABLE fact_opp_custom_fields     ENABLE ROW LEVEL SECURITY;
ALTER TABLE fact_opp_custom_fields     FORCE  ROW LEVEL SECURITY;

CREATE POLICY rls_n8n_writer_cf_contact
  ON fact_contact_custom_fields FOR ALL TO n8n_writer
  USING (TRUE) WITH CHECK (TRUE);

CREATE POLICY rls_n8n_writer_cf_opp
  ON fact_opp_custom_fields FOR ALL TO n8n_writer
  USING (TRUE) WITH CHECK (TRUE);


-- ── 5. Grants ─────────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON
  fact_contact_custom_fields, fact_opp_custom_fields
TO n8n_writer;

GRANT ALL PRIVILEGES ON
  fact_contact_custom_fields, fact_opp_custom_fields
TO sixteam_admin;


-- ── 6. Backfill contactos desde dim_contacts.custom_fields JSONB ──────────────
-- Formato JSONB: [{id: "field_id", value: "..."}, ...]
-- Detecta tipo: si parsea como DATE → value_date, si parsea como NUMERIC → value_number,
-- si no → value_text.
INSERT INTO fact_contact_custom_fields
  (contact_id, location_id, field_id, value_text, value_number, value_date, updated_at)
SELECT
  c.contact_id,
  c.location_id,
  cf->>'id'                                                    AS field_id,
  CASE
    WHEN (cf->>'value') ~ '^\d{4}-\d{2}-\d{2}'               THEN NULL
    WHEN (cf->>'value') ~ '^-?\d+(\.\d+)?$'                   THEN NULL
    ELSE cf->>'value'
  END                                                          AS value_text,
  CASE
    WHEN (cf->>'value') ~ '^-?\d+(\.\d+)?$'
    THEN (cf->>'value')::NUMERIC
  END                                                          AS value_number,
  CASE
    WHEN (cf->>'value') ~ '^\d{4}-\d{2}-\d{2}'
    THEN (substring(cf->>'value', 1, 10))::DATE
  END                                                          AS value_date,
  NOW()
FROM dim_contacts c
CROSS JOIN LATERAL jsonb_array_elements(
  CASE
    WHEN c.custom_fields IS NULL                  THEN '[]'::jsonb
    WHEN jsonb_typeof(c.custom_fields) = 'array'  THEN c.custom_fields
    ELSE '[]'::jsonb
  END
) AS cf
WHERE c.is_current = TRUE
  AND cf->>'id'    IS NOT NULL
  AND cf->>'value' IS NOT NULL
  AND cf->>'value' <> ''
ON CONFLICT (contact_id, field_id) DO UPDATE SET
  value_text   = EXCLUDED.value_text,
  value_number = EXCLUDED.value_number,
  value_date   = EXCLUDED.value_date,
  updated_at   = NOW();


-- ── 7. Conteo final ────────────────────────────────────────────────────────────
\echo '── Backfill contactos por field_id (top 20)'
SELECT
  field_id,
  COUNT(*)                   AS registros,
  COUNT(value_text)          AS texto,
  COUNT(value_number)        AS numero,
  COUNT(value_date)          AS fecha
FROM fact_contact_custom_fields
GROUP BY field_id
ORDER BY registros DESC
LIMIT 20;

\echo '── Total filas fact_contact_custom_fields'
SELECT COUNT(*) FROM fact_contact_custom_fields;

-- Template RLS por cliente (agregar en onboarding):
-- CREATE POLICY rls_cf_contact_<SLUG> ON fact_contact_custom_fields
--   FOR ALL TO client_loc_<SLUG> USING (location_id = '<LOCATION_ID>');
-- CREATE POLICY rls_cf_opp_<SLUG> ON fact_opp_custom_fields
--   FOR ALL TO client_loc_<SLUG> USING (location_id = '<LOCATION_ID>');
