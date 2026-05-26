-- ─────────────────────────────────────────────────────────────────────────────
-- 02_dim_contacts.sql — Dimensión de Contactos (SCD Tipo 2)
-- Tabla central del schema. Almacena todos los contactos de GHL con
-- versionado completo. Cada cambio en campos rastreados genera una nueva fila.
-- is_current=TRUE marca la versión activa del contacto.
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── dim_contacts ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dim_contacts (
  -- PK surrogate — nunca expuesta a GHL ni a la UI
  surrogate_key       BIGSERIAL        PRIMARY KEY,

  -- ID natural de GHL. NO UNIQUE — múltiples versiones coexisten por SCD2
  contact_id          VARCHAR(50)      NOT NULL,

  -- Subaccount de GHL — clave maestra de RLS por cliente
  location_id         VARCHAR(50)      NOT NULL,

  -- ─── Datos de contacto ───────────────────────────────────────────────────
  email               VARCHAR(255),    -- Normalizado a lowercase (regex RFC-5321)
  phone               VARCHAR(20),     -- E.164: +573001234567
  first_name          VARCHAR(100),
  last_name           VARCHAR(100),
  source              VARCHAR(100),    -- Fuente general editable en GHL
  tags                TEXT[],          -- Array de tags; índice GIN en 10_indexes
  contact_type        VARCHAR(50),     -- lead | client | other
  dnd                 BOOLEAN          DEFAULT FALSE, -- Do Not Disturb

  -- Custom fields de GHL en JSON plano (índice GIN para búsqueda por campo)
  custom_fields       JSONB,

  -- ─── Atribución — Primer toque ───────────────────────────────────────────
  utm_source_first    VARCHAR(200),    -- attributionSource.utmSource de GHL
  utm_medium_first    VARCHAR(200),
  utm_campaign_first  VARCHAR(200),    -- Campo principal de análisis de campañas
  utm_content_first   VARCHAR(200),
  utm_term_first      VARCHAR(200),
  landing_url_first   TEXT,            -- URL completa del landing page
  referrer_first      TEXT,
  gclid_first         VARCHAR(200),    -- Google Click ID (Google Ads attribution)
  fbclid_first        VARCHAR(200),    -- Facebook Click ID
  campaign_id_first   VARCHAR(100),    -- GHL attributions[].utmAdId — Meta ad ID (CTWA)
  ad_id_first         VARCHAR(100),    -- attributionSource.adId — Meta ad ID primer toque (CTWA)
  ad_id_last          VARCHAR(100),    -- lastAttributionSource.adId — Meta ad ID último toque
  ad_name_first       VARCHAR(500),    -- attributionSource.adName — nombre del anuncio (CTWA)
  ad_name_last        VARCHAR(500),    -- lastAttributionSource.adName — nombre último toque
  ctwa_clid_first     VARCHAR(500),    -- Click-to-WhatsApp click ID primer toque
  ctwa_clid_last      VARCHAR(500),    -- CTWA click ID último toque

  -- ─── Atribución — Último toque ───────────────────────────────────────────
  utm_source_last     VARCHAR(200),    -- lastAttributionSource.utmSource
  utm_medium_last     VARCHAR(200),
  utm_campaign_last   VARCHAR(200),
  utm_content_last    VARCHAR(200),
  landing_url_last    TEXT,

  -- ─── Campos de Inteligencia Artificial ───────────────────────────────────
  -- Rellenados de forma asíncrona por WF-AI-Enricher, nunca en el pipeline principal
  embedding           vector(1536),    -- Embedding perfil completo (OpenAI ada-002)
  ai_summary          TEXT,            -- Resumen generado por LLM
  ai_intent           VARCHAR(100),    -- purchase_intent | support | information | complaint
  ai_sentiment        VARCHAR(20),     -- positive | neutral | negative
  ai_lead_score       FLOAT,           -- Score 0-100 calculado por WF-AI-Enricher

  -- ─── Control SCD Tipo 2 ──────────────────────────────────────────────────
  valid_from          TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  valid_to            TIMESTAMPTZ,     -- NULL = registro actualmente activo
  is_current          BOOLEAN          NOT NULL DEFAULT TRUE,
  change_reason       VARCHAR(200),    -- email_change | phone_change | source_change, etc.

  -- ─── Timestamps de GHL y sincronización ─────────────────────────────────
  ghl_created_at      TIMESTAMPTZ,
  ghl_updated_at      TIMESTAMPTZ,
  synced_at           TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE dim_contacts IS
  'Dimensión SCD Tipo 2 de contactos de GHL. '
  'is_current=TRUE marca la versión vigente. '
  'location_id es la clave de Row Level Security por cliente.';
