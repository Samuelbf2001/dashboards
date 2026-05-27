-- ─────────────────────────────────────────────────────────────────────────────
-- V1.0.8 — Mapeo canónico de Custom Fields multi-location
--
-- Problema: en GHL cada sub-cuenta tiene IDs únicos para sus custom fields.
-- Ejemplo: el campo "ciudad" puede ser  j7l3xqmm5kBNQfNXLKaO en una location
--          y aB3kxnpQrW2sLmYzT8vU       en otra.
--
-- Solución: 4 tablas
--   1. ghl_custom_field_defs  — catálogo canónico (canonical_key, data_type)
--   2. ghl_custom_field_map   — mapeo por location (location → ghl_field_id → canonical_key)
--   3. fact_contact_custom_fields  — facts normalizados de contactos (long format)
--   4. fact_opp_custom_fields      — facts normalizados de oportunidades (long format)
--
-- Comportamiento: si un webhook trae un ghl_field_id que NO está mapeado para
-- esa location, se ignora silenciosamente. El dato sigue disponible en
-- dim_contacts.custom_fields / dim_opportunities.custom_fields (JSONB).
--
-- RLS habilitada y forzada en las dos fact tables (mismo patrón que dim_*).
-- ─────────────────────────────────────────────────────────────────────────────


-- ─── 1. Catálogo canónico (compartido entre clientes) ────────────────────────
CREATE TABLE IF NOT EXISTS ghl_custom_field_defs (
  canonical_key  VARCHAR(60)   PRIMARY KEY,
  entity_type    VARCHAR(20)   NOT NULL CHECK (entity_type IN ('contact','opportunity')),
  data_type      VARCHAR(20)   NOT NULL CHECK (data_type   IN ('text','number','date','boolean','select')),
  label_es       VARCHAR(120),
  notes          TEXT,
  created_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  ghl_custom_field_defs IS
  'Catálogo de campos canónicos compartidos. Define qué campos lógicos tracquea el sistema.';
COMMENT ON COLUMN ghl_custom_field_defs.canonical_key IS
  'Identificador estable en snake_case (ej: ciudad, presupuesto, producto_interes).';
COMMENT ON COLUMN ghl_custom_field_defs.entity_type IS
  'contact o opportunity — define a qué fact table va.';
COMMENT ON COLUMN ghl_custom_field_defs.data_type IS
  'text|number|date|boolean|select — determina en qué columna value_* se almacena.';


-- ─── 2. Mapeo por location (1 fila por (location, canonical) — o (location, ghl_field_id)) ─
CREATE TABLE IF NOT EXISTS ghl_custom_field_map (
  location_id      VARCHAR(50)  NOT NULL REFERENCES ghl_locations(location_id) ON DELETE CASCADE,
  ghl_field_id     VARCHAR(100) NOT NULL,
  canonical_key    VARCHAR(60)  NOT NULL REFERENCES ghl_custom_field_defs(canonical_key),
  ghl_field_name   VARCHAR(200),                    -- nombre que el cliente le puso en GHL (referencia)
  active           BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  PRIMARY KEY (location_id, ghl_field_id),
  UNIQUE       (location_id, canonical_key)
);

COMMENT ON TABLE  ghl_custom_field_map IS
  'Mapeo location_id + ghl_field_id → canonical_key. 1 fila por campo activo por cliente.';
COMMENT ON COLUMN ghl_custom_field_map.active IS
  'FALSE = pausar este mapeo (no escribir a fact_* en webhooks). Se mantiene historial.';

CREATE INDEX IF NOT EXISTS idx_cfmap_active_field
  ON ghl_custom_field_map(location_id, ghl_field_id) WHERE active = TRUE;


-- ─── 3. fact_contact_custom_fields (long format) ─────────────────────────────
CREATE TABLE IF NOT EXISTS fact_contact_custom_fields (
  contact_id      VARCHAR(50)  NOT NULL,
  location_id     VARCHAR(50)  NOT NULL,
  canonical_key   VARCHAR(60)  NOT NULL REFERENCES ghl_custom_field_defs(canonical_key),
  value_text      TEXT,
  value_number    NUMERIC(20,4),
  value_date      DATE,
  value_bool      BOOLEAN,
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  PRIMARY KEY (contact_id, canonical_key)
);

COMMENT ON TABLE fact_contact_custom_fields IS
  'Custom fields normalizados de contactos. 1 fila por (contact_id, canonical_key).';

CREATE INDEX IF NOT EXISTS idx_fact_cf_contact_location
  ON fact_contact_custom_fields(location_id);

CREATE INDEX IF NOT EXISTS idx_fact_cf_contact_canonical
  ON fact_contact_custom_fields(canonical_key, location_id);


-- ─── 4. fact_opp_custom_fields (long format) ─────────────────────────────────
CREATE TABLE IF NOT EXISTS fact_opp_custom_fields (
  opportunity_id  VARCHAR(50)  NOT NULL,
  location_id     VARCHAR(50)  NOT NULL,
  canonical_key   VARCHAR(60)  NOT NULL REFERENCES ghl_custom_field_defs(canonical_key),
  value_text      TEXT,
  value_number    NUMERIC(20,4),
  value_date      DATE,
  value_bool      BOOLEAN,
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  PRIMARY KEY (opportunity_id, canonical_key)
);

COMMENT ON TABLE fact_opp_custom_fields IS
  'Custom fields normalizados de oportunidades. 1 fila por (opportunity_id, canonical_key).';

CREATE INDEX IF NOT EXISTS idx_fact_cf_opp_location
  ON fact_opp_custom_fields(location_id);

CREATE INDEX IF NOT EXISTS idx_fact_cf_opp_canonical
  ON fact_opp_custom_fields(canonical_key, location_id);


-- ─── 5. RLS (mismo patrón que db/init/11_rls_policies.sql) ───────────────────
ALTER TABLE fact_contact_custom_fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE fact_contact_custom_fields FORCE  ROW LEVEL SECURITY;
ALTER TABLE fact_opp_custom_fields     ENABLE ROW LEVEL SECURITY;
ALTER TABLE fact_opp_custom_fields     FORCE  ROW LEVEL SECURITY;

-- Permisiva para n8n_writer (ingestión sin restricción)
DROP POLICY IF EXISTS rls_n8n_writer_cf_contact ON fact_contact_custom_fields;
CREATE POLICY rls_n8n_writer_cf_contact
  ON fact_contact_custom_fields
  FOR ALL TO n8n_writer
  USING (TRUE) WITH CHECK (TRUE);

DROP POLICY IF EXISTS rls_n8n_writer_cf_opp ON fact_opp_custom_fields;
CREATE POLICY rls_n8n_writer_cf_opp
  ON fact_opp_custom_fields
  FOR ALL TO n8n_writer
  USING (TRUE) WITH CHECK (TRUE);


-- ─── 6. Grants ───────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON
  ghl_custom_field_defs,
  ghl_custom_field_map,
  fact_contact_custom_fields,
  fact_opp_custom_fields
TO n8n_writer;

GRANT ALL PRIVILEGES ON
  ghl_custom_field_defs,
  ghl_custom_field_map,
  fact_contact_custom_fields,
  fact_opp_custom_fields
TO sixteam_admin;


-- ─── 7. Template de policy por cliente (a aplicar en onboarding) ─────────────
-- Reemplazar <SLUG> y <LOCATION_ID>:
--
-- CREATE POLICY rls_cf_contact_<SLUG> ON fact_contact_custom_fields
--   FOR ALL TO client_loc_<SLUG>
--   USING (location_id = '<LOCATION_ID>');
--
-- CREATE POLICY rls_cf_opp_<SLUG> ON fact_opp_custom_fields
--   FOR ALL TO client_loc_<SLUG>
--   USING (location_id = '<LOCATION_ID>');

-- Verificación:
-- \d+ fact_contact_custom_fields
-- \d+ fact_opp_custom_fields
-- SELECT canonical_key, entity_type, data_type FROM ghl_custom_field_defs ORDER BY 1;
