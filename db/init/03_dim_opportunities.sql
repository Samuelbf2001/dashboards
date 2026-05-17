-- ─────────────────────────────────────────────────────────────────────────────
-- 03_dim_opportunities.sql — Dimensión de Oportunidades (SCD Tipo 2)
-- Oportunidades/negocios de GHL con versionado completo. Cada cambio de etapa,
-- valor monetario o asignación de asesor genera una nueva versión.
-- Permite saber el estado de cualquier oportunidad en cualquier punto pasado.
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── dim_opportunities ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dim_opportunities (
  -- PK surrogate
  surrogate_key       BIGSERIAL        PRIMARY KEY,

  -- ID natural de GHL. NO UNIQUE — múltiples versiones por SCD2
  opportunity_id      VARCHAR(50)      NOT NULL,

  -- FK lógica a dim_contacts (sin constraint físico para flexibilidad ETL)
  contact_id          VARCHAR(50)      NOT NULL,

  -- Subaccount GHL — clave de RLS por cliente
  location_id         VARCHAR(50)      NOT NULL,

  -- ─── Pipeline ────────────────────────────────────────────────────────────
  -- FK lógica a dim_pipelines (sin constraint físico)
  pipeline_id         VARCHAR(50),
  pipeline_name       VARCHAR(200),    -- Desnormalizado para performance en BI

  pipeline_stage_id   VARCHAR(50),     -- ID de la etapa actual
  stage_name          VARCHAR(200),    -- Nombre de la etapa (desnormalizado)

  -- ─── Estado y valor ──────────────────────────────────────────────────────
  status              VARCHAR(20),     -- open | won | lost | abandoned
  monetary_value      NUMERIC(15,2)    DEFAULT 0,
  currency            VARCHAR(3)       DEFAULT 'COP', -- ISO 4217; default Colombia

  -- ─── Asignación ──────────────────────────────────────────────────────────
  assigned_to_user_id VARCHAR(50),
  assigned_to_name    VARCHAR(200),    -- Nombre del asesor (desnormalizado)

  -- ─── Campos adicionales ──────────────────────────────────────────────────
  custom_fields       JSONB,           -- Custom fields de la oportunidad en JSON
  close_date          DATE,            -- Fecha estimada de cierre

  -- ─── Campos de Inteligencia Artificial ───────────────────────────────────
  ai_win_probability  FLOAT,           -- Probabilidad de ganar (0-1) calculada por IA
  ai_next_action      TEXT,            -- Próxima acción recomendada por IA

  -- ─── Control SCD Tipo 2 ──────────────────────────────────────────────────
  valid_from          TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  valid_to            TIMESTAMPTZ,     -- NULL = versión activa
  is_current          BOOLEAN          NOT NULL DEFAULT TRUE,
  change_reason       VARCHAR(200),    -- stage_change | value_change | assignment_change | status_change

  -- ─── Timestamps ──────────────────────────────────────────────────────────
  ghl_created_at      TIMESTAMPTZ,
  ghl_updated_at      TIMESTAMPTZ,
  synced_at           TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE dim_opportunities IS
  'Dimensión SCD Tipo 2 de oportunidades de GHL. '
  'Cada cambio de etapa/valor/asignación genera nueva versión. '
  'is_current=TRUE marca la versión vigente.';
