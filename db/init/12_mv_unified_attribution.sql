-- ─────────────────────────────────────────────────────────────────────────────
-- 12_mv_unified_attribution.sql — Vista Materializada de Atribución Unificada
-- Consolida contacts + opportunities + conversations + CTWA en una sola fila
-- por par contacto-oportunidad. Es el origen principal de los dashboards de Metabase.
-- Se refresca automáticamente cada hora con pg_cron (13_pg_cron.sql).
--
-- REFRESH CONCURRENTLY requiere un índice UNIQUE sobre la vista.
-- Se crea el índice único compuesto (contact_id, opportunity_id, ctwa_clid)
-- para satisfacer este requisito dado que la vista no tiene PK natural simple.
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── mv_unified_attribution ───────────────────────────────────────────────────
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_unified_attribution AS
SELECT
  c.contact_id,
  c.location_id,
  c.first_name,
  c.last_name,
  c.email,
  c.phone,

  -- ─── Fuente unificada: CTWA tiene prioridad sobre UTM ────────────────────
  COALESCE(ct.campaign_id,   c.campaign_id_first)     AS campaign_id,
  COALESCE(ct.campaign_name, c.utm_campaign_first)    AS campaign_name,
  COALESCE(ct.ad_name,       c.utm_content_first)     AS ad_name,

  CASE
    WHEN ct.id IS NOT NULL     THEN 'whatsapp_ctwa'
    WHEN c.utm_source_first IS NOT NULL THEN c.utm_source_first
    ELSE c.source
  END                                                 AS attributed_source,

  CASE
    WHEN ct.id IS NOT NULL THEN 'paid_social_wa'
    ELSE c.utm_medium_first
  END                                                 AS attributed_medium,

  -- ─── Oportunidad ─────────────────────────────────────────────────────────
  o.opportunity_id,
  o.pipeline_name,
  o.stage_name,
  o.status                                            AS opp_status,
  o.monetary_value,
  o.ghl_created_at                                    AS opp_created_at,

  -- ─── Conversación ────────────────────────────────────────────────────────
  cv.conversation_id,
  cv.channel_type,
  cv.first_reply_seconds,

  -- ─── IA ──────────────────────────────────────────────────────────────────
  cv.ai_intent,
  cv.ai_sentiment,
  c.ai_lead_score,

  -- ─── Timestamps ──────────────────────────────────────────────────────────
  c.ghl_created_at                                    AS contact_created_at,
  ct.clicked_at                                       AS ad_clicked_at,
  ct.ctwa_clid

FROM dim_contacts c

LEFT JOIN dim_opportunities o
  ON o.contact_id = c.contact_id AND o.is_current

LEFT JOIN dim_conversations cv
  ON cv.contact_id = c.contact_id AND cv.is_current

LEFT JOIN fact_ctwa_clicks ct
  ON ct.contact_id = c.contact_id

WHERE c.is_current

WITH DATA;

-- ─── Índice UNIQUE requerido para REFRESH CONCURRENTLY ───────────────────────
-- El par (contact_id, opportunity_id, ctwa_clid) identifica de forma única
-- cada fila en la vista dado que un contacto puede tener múltiples oportunidades
-- y múltiples clicks CTWA; NULL se trata como valor distinto en índices UNIQUE.
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_unique_row
  ON mv_unified_attribution(
    contact_id,
    COALESCE(opportunity_id, ''),
    COALESCE(ctwa_clid, '')
  );

-- ─── Índices de rendimiento sobre la MV ──────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_mv_location
  ON mv_unified_attribution(location_id);

CREATE INDEX IF NOT EXISTS idx_mv_campaign
  ON mv_unified_attribution(campaign_name);

CREATE INDEX IF NOT EXISTS idx_mv_opp_status
  ON mv_unified_attribution(opp_status);

CREATE INDEX IF NOT EXISTS idx_mv_attributed_src
  ON mv_unified_attribution(attributed_source);
