-- ─────────────────────────────────────────────────────────────────────────────
-- 08_fact_ctwa_clicks.sql — Clicks CTWA de Meta (Fact de Atribución)
-- Capturado del objeto referral del webhook de Meta Cloud API.
-- Contiene el ctwa_clid para enviar conversion events a Meta CAPI.
-- Es el puente entre gasto publicitario y CRM — información que GHL no captura.
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── fact_ctwa_clicks ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fact_ctwa_clicks (
  id                  BIGSERIAL        PRIMARY KEY,

  -- Click ID único de Meta — UNIQUE; es el campo que atribuye conversiones en Meta CAPI
  ctwa_clid           VARCHAR(500)     NOT NULL UNIQUE,

  -- Número E.164 del usuario — clave de correlación con dim_contacts
  phone               VARCHAR(20)      NOT NULL,

  -- ─── Datos del anuncio (del objeto referral de Meta) ─────────────────────
  -- FK lógica a dim_ads.ad_id
  ad_id               VARCHAR(100),
  ad_name             VARCHAR(500),    -- Nombre del anuncio al momento del click

  adset_id            VARCHAR(100),
  adset_name          VARCHAR(500),

  campaign_id         VARCHAR(100),    -- ID de la campaña Meta
  campaign_name       VARCHAR(500),

  source_url          TEXT,            -- URL del anuncio (fb.me/...)
  headline            TEXT,            -- Titular del anuncio al momento del click
  body_text           TEXT,            -- Cuerpo del anuncio al momento del click

  -- ─── Correlación con GHL (rellenada por WF-11) ───────────────────────────
  -- Inicialmente NULL; WF-11 lo rellena cuando GHL crea el contacto
  contact_id          VARCHAR(50),     -- ID del contacto GHL correlacionado por phone
  conversation_id     VARCHAR(50),     -- ID de conversación GHL (rellenado por WF-11)

  -- Subaccount GHL — RLS (rellenado por WF-11 tras correlación)
  location_id         VARCHAR(50),

  -- ─── Conversión ──────────────────────────────────────────────────────────
  converted_to_opp_id VARCHAR(50),     -- ID de la oportunidad ganada (para calcular ROAS real)
  converted_at        TIMESTAMPTZ,
  conversion_value    NUMERIC(15,2),   -- Valor monetario para optimización de Meta CAPI

  -- ─── Meta Conversions API (CAPI) ─────────────────────────────────────────
  capi_sent_at        TIMESTAMPTZ,     -- Cuando se envió el conversion event a Meta CAPI
  capi_event_id       VARCHAR(200),    -- Event ID devuelto por Meta CAPI (deduplicación)
  capi_payload        JSONB,           -- Payload completo enviado para auditoría y debugging

  -- ─── Timestamps ──────────────────────────────────────────────────────────
  clicked_at          TIMESTAMPTZ      NOT NULL, -- Cuando el usuario hizo clic en el anuncio
  first_message_at    TIMESTAMPTZ      -- Cuando el usuario envió el primer mensaje de WhatsApp
);

COMMENT ON TABLE fact_ctwa_clicks IS
  'Clicks en anuncios Click-to-WhatsApp de Meta. '
  'ctwa_clid es el campo que atribuye conversiones en Meta CAPI. '
  'contact_id y location_id son NULL hasta que WF-11 correlaciona por phone (E.164).';
