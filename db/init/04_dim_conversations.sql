-- ─────────────────────────────────────────────────────────────────────────────
-- 04_dim_conversations.sql — Dimensión de Conversaciones (SCD Tipo 2)
-- Hilo de conversación en GHL (WhatsApp, SMS, Email, llamada, IG, etc.).
-- SCD Tipo 2 para cambios de asignación o estado.
-- first_reply_seconds es el KPI principal de velocidad de respuesta al lead.
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── dim_conversations ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dim_conversations (
  -- PK surrogate
  surrogate_key        BIGSERIAL        PRIMARY KEY,

  -- ID natural de GHL
  conversation_id      VARCHAR(50)      NOT NULL,

  -- FK lógica a dim_contacts
  contact_id           VARCHAR(50)      NOT NULL,

  -- Subaccount GHL — clave de RLS por cliente
  location_id          VARCHAR(50)      NOT NULL,

  -- ─── Canal ───────────────────────────────────────────────────────────────
  channel_type         VARCHAR(30),     -- WHATSAPP | SMS | EMAIL | FB_MESSENGER | INSTAGRAM | CALL
  inbox_id             VARCHAR(50),
  inbox_name           VARCHAR(200),    -- Desnormalizado

  -- ─── Asignación ──────────────────────────────────────────────────────────
  assigned_user_id     VARCHAR(50),
  assigned_user_name   VARCHAR(200),    -- Desnormalizado

  -- ─── Estado ──────────────────────────────────────────────────────────────
  status               VARCHAR(20),     -- open | closed
  unread_count         INT              DEFAULT 0,

  -- ─── Atribución CTWA ─────────────────────────────────────────────────────
  -- ctwa_click_id: FK a fact_ctwa_clicks.id (presente si inició desde anuncio CTWA)
  ctwa_click_id        BIGINT,
  ad_id                VARCHAR(100),    -- ID del anuncio Meta (desnormalizado de fact_ctwa_clicks)
  ad_name              VARCHAR(500),
  campaign_id          VARCHAR(100),    -- ID de la campaña Meta
  campaign_name        VARCHAR(500),

  -- ─── KPIs de tiempo de respuesta ─────────────────────────────────────────
  first_inbound_at     TIMESTAMPTZ,     -- Primer mensaje entrante del contacto
  first_outbound_at    TIMESTAMPTZ,     -- Primer mensaje saliente del asesor o bot
  last_message_at      TIMESTAMPTZ,     -- Último mensaje en cualquier dirección

  -- KPI principal: segundos entre first_inbound_at y first_outbound_at
  -- Calculado por n8n al recibir el primer mensaje outbound
  first_reply_seconds  BIGINT,

  -- ─── Campos de Inteligencia Artificial ───────────────────────────────────
  ai_summary           TEXT,            -- Resumen del hilo generado por LLM
  ai_intent            VARCHAR(100),    -- purchase_intent | support | pricing_inquiry | appointment_request | complaint
  ai_sentiment         VARCHAR(20),     -- positive | neutral | negative
  ai_resolution        VARCHAR(50),     -- resolved | unresolved | escalated | pending

  -- Embedding del hilo completo para búsqueda semántica de conversaciones similares
  embedding            vector(1536),

  -- ─── Control SCD Tipo 2 ──────────────────────────────────────────────────
  valid_from           TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  valid_to             TIMESTAMPTZ,
  is_current           BOOLEAN          NOT NULL DEFAULT TRUE,

  -- ─── Timestamps ──────────────────────────────────────────────────────────
  ghl_created_at       TIMESTAMPTZ,
  synced_at            TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE dim_conversations IS
  'Dimensión SCD Tipo 2 de conversaciones de GHL. '
  'first_reply_seconds es el KPI de velocidad de respuesta al lead. '
  'ctwa_click_id vincula directamente al anuncio Meta que originó el chat.';
