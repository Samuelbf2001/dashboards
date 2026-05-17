-- ─────────────────────────────────────────────────────────────────────────────
-- 05_dim_pipelines_ads.sql — Dimensiones de Pipelines y Anuncios Meta
-- dim_pipelines: referencia de pipelines y etapas de GHL (dimensión estática)
-- dim_ads: catálogo de anuncios de Meta Ads con presupuesto y estado
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── dim_pipelines ────────────────────────────────────────────────────────────
-- Tabla de referencia de pipelines y etapas de GHL.
-- Resincronizada cada vez que se detecta un pipeline_id nuevo en una oportunidad.
-- Permite decodificar IDs, conocer el orden de etapas y distinguir etapas won/lost.
CREATE TABLE IF NOT EXISTS dim_pipelines (
  id            BIGSERIAL        PRIMARY KEY,

  -- ID del pipeline en GHL (no unique — un pipeline tiene múltiples etapas)
  pipeline_id   VARCHAR(50)      NOT NULL,
  pipeline_name VARCHAR(200),

  -- Etapa dentro del pipeline
  stage_id      VARCHAR(50)      NOT NULL,
  stage_name    VARCHAR(200),

  -- Posición ordinal para renderizar el funnel en orden correcto
  stage_order   INT,

  -- Flags para calcular tasas de conversión correctamente
  is_won_stage  BOOLEAN          DEFAULT FALSE, -- TRUE si es etapa de venta cerrada ganada
  is_lost_stage BOOLEAN          DEFAULT FALSE, -- TRUE si es etapa de abandono o cierre perdido

  -- Subaccount GHL — RLS
  location_id   VARCHAR(50)      NOT NULL,

  synced_at     TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE dim_pipelines IS
  'Dimensión de referencia de pipelines y etapas de GHL. '
  'Una fila por par (pipeline_id, stage_id). '
  'is_won_stage y is_lost_stage permiten calcular tasas de conversión.';


-- ─── dim_ads ──────────────────────────────────────────────────────────────────
-- Catálogo de anuncios Meta Ads (campaña → adset → anuncio).
-- Sincronizado desde Meta Marketing API.
-- Enriquece fact_ctwa_clicks sin JOINs costosos en cada query de analytics.
CREATE TABLE IF NOT EXISTS dim_ads (
  id             BIGSERIAL        PRIMARY KEY,

  -- ID único del anuncio en Meta Ads Manager — UNIQUE constraint
  ad_id          VARCHAR(100)     NOT NULL UNIQUE,
  ad_name        VARCHAR(500),

  -- Adset padre
  adset_id       VARCHAR(100),
  adset_name     VARCHAR(500),

  -- Campaña padre
  campaign_id    VARCHAR(100),
  campaign_name  VARCHAR(500),

  -- Cuenta de Meta Ads
  account_id     VARCHAR(100),

  -- Subaccount GHL que usa este anuncio — RLS
  location_id    VARCHAR(50)      NOT NULL,

  -- ─── Configuración del anuncio ───────────────────────────────────────────
  objective      VARCHAR(100),    -- MESSAGES (CTWA) | CONVERSIONS | LEAD_GENERATION
  status         VARCHAR(20),     -- ACTIVE | PAUSED | ARCHIVED

  -- ─── Presupuesto y gasto ─────────────────────────────────────────────────
  daily_budget   NUMERIC(15,2),   -- Presupuesto diario en moneda de la cuenta Meta Ads
  lifetime_spend NUMERIC(15,2)    DEFAULT 0, -- Gasto total histórico (actualizado periódicamente)

  -- ─── Fechas ──────────────────────────────────────────────────────────────
  start_date     DATE,
  end_date       DATE,            -- Fecha de fin programada (si aplica)

  synced_at      TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE dim_ads IS
  'Catálogo de anuncios de Meta Ads (estructura campaña→adset→anuncio). '
  'Enriquece fact_ctwa_clicks con datos de presupuesto sin JOINs adicionales. '
  'Sincronizado desde Meta Marketing API.';
