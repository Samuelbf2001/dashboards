-- ─────────────────────────────────────────────────────────────────────────────
-- 07_fact_history_email.sql — Historial de etapas y eventos de email
-- fact_opp_stage_history: movimiento histórico de oportunidades entre etapas
--   Capturado exclusivamente por el webhook OpportunityUpdate (lo que GHL no guarda)
-- fact_email_events: opens, clicks y bounces de emails vía Mailgun/SendGrid
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── fact_opp_stage_history ───────────────────────────────────────────────────
-- Historial completo de movimientos de oportunidades entre etapas del pipeline.
-- Tabla append-only — cada cambio de etapa es una nueva fila con snapshot.
-- Permite calcular velocity, tiempo en etapa y funnel real de conversión.
CREATE TABLE IF NOT EXISTS fact_opp_stage_history (
  id                     BIGSERIAL        PRIMARY KEY,

  -- ID de la oportunidad en GHL
  opportunity_id         VARCHAR(50)      NOT NULL,

  -- ID del contacto dueño (desnormalizado)
  contact_id             VARCHAR(50)      NOT NULL,

  -- Subaccount GHL — RLS
  location_id            VARCHAR(50)      NOT NULL,

  -- ─── Etapas ──────────────────────────────────────────────────────────────
  from_stage_id          VARCHAR(50),     -- Etapa de origen (NULL en primera asignación)
  from_stage_name        VARCHAR(200),    -- Nombre de la etapa de origen (desnormalizado al momento del evento)
  to_stage_id            VARCHAR(50),     -- Etapa de destino
  to_stage_name          VARCHAR(200),    -- Nombre de la etapa de destino

  -- ─── Pipeline ────────────────────────────────────────────────────────────
  pipeline_id            VARCHAR(50),
  pipeline_name          VARCHAR(200),    -- Desnormalizado

  -- ─── Snapshot del momento del cambio ─────────────────────────────────────
  monetary_value         NUMERIC(15,2),   -- Valor de la oportunidad EN EL MOMENTO del cambio
  status_at_change       VARCHAR(20),     -- open | won | lost en el momento del cambio
  assigned_user_id       VARCHAR(50),     -- Asesor asignado en el momento del cambio

  -- Segundos en la etapa anterior (calculado por n8n: changed_at menos el changed_at anterior)
  time_in_prev_stage_sec BIGINT,

  -- ─── Metadatos del evento ────────────────────────────────────────────────
  changed_at             TIMESTAMPTZ      NOT NULL, -- Timestamp exacto del cambio (del webhook GHL)
  triggered_by           VARCHAR(50)      -- webhook | api_manual | workflow_automation
);

COMMENT ON TABLE fact_opp_stage_history IS
  'Historial append-only de movimientos de oportunidades entre etapas. '
  'Capturado exclusivamente por webhook OpportunityUpdate. '
  'time_in_prev_stage_sec permite calcular velocity y tiempo por etapa.';


-- ─── fact_email_events ────────────────────────────────────────────────────────
-- Eventos de email capturados desde Mailgun o SendGrid.
-- Correlaciona con fact_messages mediante email_message_id.
-- Disponible SOLO con Mailgun o SendGrid como ESP (no con SMTP genérico).
CREATE TABLE IF NOT EXISTS fact_email_events (
  id            BIGSERIAL        PRIMARY KEY,

  -- ID único del evento en el ESP — UNIQUE constraint previene duplicados
  event_id      VARCHAR(200)     NOT NULL UNIQUE,

  -- Message-ID SMTP del email original — FK a fact_messages.email_message_id
  message_id    VARCHAR(200),

  -- Contacto GHL correlacionado por email address
  contact_id    VARCHAR(50),

  -- Subaccount GHL — RLS
  location_id   VARCHAR(50)      NOT NULL,

  -- ─── Tipo de evento ──────────────────────────────────────────────────────
  event_type    VARCHAR(30)      NOT NULL, -- delivered | opened | clicked | bounced | unsubscribed | spam_reported

  -- ─── Email ───────────────────────────────────────────────────────────────
  email         VARCHAR(255),    -- Email del destinatario del evento
  subject       VARCHAR(500),    -- Asunto del email

  -- ─── Datos del evento ────────────────────────────────────────────────────
  url           TEXT,            -- URL clickeada (solo event_type=clicked)
  bounce_type   VARCHAR(30),     -- hard (permanente) | soft (temporal)
  bounce_reason TEXT,            -- Mensaje de error del ESP sobre el bounce

  -- ─── Metadatos del cliente de email ──────────────────────────────────────
  client_type   VARCHAR(50),     -- Gmail | Outlook | Apple Mail | Yahoo Mail
  device_type   VARCHAR(30),     -- desktop | mobile | tablet
  country       VARCHAR(2),      -- Código ISO 3166-1 alfa-2

  -- ─── Origen ──────────────────────────────────────────────────────────────
  esp           VARCHAR(20),     -- mailgun | sendgrid

  -- ─── Timestamp ───────────────────────────────────────────────────────────
  occurred_at   TIMESTAMPTZ      NOT NULL -- Timestamp del evento según el ESP
);

COMMENT ON TABLE fact_email_events IS
  'Tabla append-only de eventos de email (Mailgun/SendGrid). '
  'event_id UNIQUE previene duplicados. '
  'message_id correlaciona con fact_messages.email_message_id.';
