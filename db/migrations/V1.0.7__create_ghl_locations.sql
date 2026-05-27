-- ─────────────────────────────────────────────────────────────────────────────
-- V1.0.7 — Registro de locations (sub-cuentas GHL)
--
-- Reemplaza la lista hardcodeada en GHL_LOCATION_IDS (env var de n8n) por una
-- tabla en BD. Permite agregar clientes nuevos sin redeploy y referenciar la
-- relación location_id ↔ client desde el resto del esquema.
--
-- Sin webhook_secret: la autenticidad del webhook se valida con HMAC global.
-- Sin ghl_api_token: no hay polling; todo entra por webhooks GHL → n8n.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ghl_locations (
  location_id            VARCHAR(50)   PRIMARY KEY,
  client_name            VARCHAR(120)  NOT NULL,
  client_slug            VARCHAR(60)   NOT NULL UNIQUE,
  metabase_dashboard_id  INTEGER,
  active                 BOOLEAN       NOT NULL DEFAULT TRUE,
  notes                  TEXT,
  created_at             TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at             TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  ghl_locations IS
  'Registro de sub-cuentas GHL activas. 1 fila por cliente.';
COMMENT ON COLUMN ghl_locations.location_id IS
  'ID de la sub-cuenta en GHL (globalmente único en toda la plataforma).';
COMMENT ON COLUMN ghl_locations.client_slug IS
  'Identificador corto en kebab-case. Usado como sufijo en vistas, roles y nombres de dashboard.';
COMMENT ON COLUMN ghl_locations.metabase_dashboard_id IS
  'ID numérico del dashboard clonado en Metabase para este cliente (referencia, no FK).';
COMMENT ON COLUMN ghl_locations.active IS
  'FALSE = pausar ingestión de webhooks para este cliente.';

CREATE INDEX IF NOT EXISTS idx_ghl_locations_active
  ON ghl_locations(active) WHERE active = TRUE;

-- ── Trigger para mantener updated_at ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION trg_ghl_locations_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_ghl_locations_updated_at ON ghl_locations;
CREATE TRIGGER trg_ghl_locations_updated_at
  BEFORE UPDATE ON ghl_locations
  FOR EACH ROW EXECUTE FUNCTION trg_ghl_locations_set_updated_at();

-- ── Seed inicial: milotecucuta (cliente existente con datos en producción) ──
INSERT INTO ghl_locations (location_id, client_name, client_slug, notes)
VALUES
  ('0IP2MEmSx0fpdVllDK5b', 'Milote Cúcuta', 'milotecucuta',
   'Primer cliente productivo. Seed de dim_ads en scripts/V1.0.3__seed_dim_ads_milotecucuta.sql.')
ON CONFLICT (location_id) DO NOTHING;

-- Verificación:
-- SELECT location_id, client_name, client_slug, active, metabase_dashboard_id
-- FROM ghl_locations ORDER BY created_at;
