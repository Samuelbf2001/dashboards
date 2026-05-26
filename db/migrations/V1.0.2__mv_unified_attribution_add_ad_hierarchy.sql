-- ─────────────────────────────────────────────────────────────────────────────
-- V1.0.2 — Agregar jerarquía completa de anuncios a mv_unified_attribution
--
-- Cambios:
--   • JOIN con dim_ads para enriquecer con adset_id/name, campaign_id/name
--   • Nuevas columnas expuestas: ad_id, adset_id, adset_name
--   • campaign_id y campaign_name ahora usan dim_ads como fuente prioritaria
--
-- Requiere DROP + CREATE porque se agregan columnas (no hay ALTER en MV).
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Eliminar índices dependientes de la MV
DROP INDEX IF EXISTS idx_mv_unique_row;
DROP INDEX IF EXISTS idx_mv_location;
DROP INDEX IF EXISTS idx_mv_campaign;
DROP INDEX IF EXISTS idx_mv_opp_status;
DROP INDEX IF EXISTS idx_mv_attributed_src;

-- 2. Eliminar la MV existente
DROP MATERIALIZED VIEW IF EXISTS mv_unified_attribution;

-- 3. Recrear con la jerarquía completa de anuncios
CREATE MATERIALIZED VIEW mv_unified_attribution AS
SELECT
  c.contact_id,
  c.location_id,
  c.first_name,
  c.last_name,
  c.email,
  c.phone,

  -- ─── Jerarquía de anuncio — dim_ads enriquece cuando está poblado ────────
  ct.ad_id,
  COALESCE(d.ad_name,       ct.ad_name,       c.utm_content_first)     AS ad_name,
  COALESCE(d.adset_id,      ct.adset_id)                               AS adset_id,
  COALESCE(d.adset_name,    ct.adset_name)                             AS adset_name,
  COALESCE(d.campaign_id,   ct.campaign_id,   c.campaign_id_first)     AS campaign_id,
  COALESCE(d.campaign_name, ct.campaign_name, c.utm_campaign_first)    AS campaign_name,

  CASE
    WHEN ct.id IS NOT NULL              THEN 'whatsapp_ctwa'
    WHEN c.utm_source_first IS NOT NULL THEN c.utm_source_first
    ELSE c.source
  END                                                                   AS attributed_source,

  CASE
    WHEN ct.id IS NOT NULL THEN 'paid_social_wa'
    ELSE c.utm_medium_first
  END                                                                   AS attributed_medium,

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

LEFT JOIN dim_ads d
  ON d.ad_id = ct.ad_id

WHERE c.is_current

WITH DATA;

-- 4. Índice UNIQUE requerido para REFRESH CONCURRENTLY
CREATE UNIQUE INDEX idx_mv_unique_row
  ON mv_unified_attribution(
    contact_id,
    COALESCE(opportunity_id, ''),
    COALESCE(ctwa_clid, '')
  );

-- 5. Índices de rendimiento
CREATE INDEX idx_mv_location       ON mv_unified_attribution(location_id);
CREATE INDEX idx_mv_campaign       ON mv_unified_attribution(campaign_name);
CREATE INDEX idx_mv_opp_status     ON mv_unified_attribution(opp_status);
CREATE INDEX idx_mv_attributed_src ON mv_unified_attribution(attributed_source);
CREATE INDEX idx_mv_ad_id          ON mv_unified_attribution(ad_id);
