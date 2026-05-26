-- ─────────────────────────────────────────────────────────────────────────────
-- V1.0.6 — Actualizar mv_unified_attribution con dual JOIN a dim_ads
--
-- Problema anterior: la MV enrutaba toda la atribución de anuncios a través de
-- fact_ctwa_clicks (tabla vacía), dejando ad_name = NULL para el 100% de contactos.
--
-- Solución: doble JOIN directo a dim_ads desde dim_contacts:
--   • Path A: campaign_id_first = GHL attributions[].utmAdId  → contactos CTWA
--   • Path B: utm_content_first = ?utm_content= URL param     → contactos UTM fb/ig
--
-- Prioridad COALESCE para ad_name:
--   1. ad_name_first  — GHL popula directamente (CTWA con nombre)
--   2. d_ctwa.ad_name — via fact_ctwa_clicks (preparado para datos futuros)
--   3. d_camp.ad_name — via campaign_id_first (CTWA sin nombre directo)
--   4. d_utm.ad_name  — via utm_content_first (UTM fb/ig)
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Eliminar índices dependientes de la MV
DROP INDEX IF EXISTS idx_mv_unique_row;
DROP INDEX IF EXISTS idx_mv_location;
DROP INDEX IF EXISTS idx_mv_campaign;
DROP INDEX IF EXISTS idx_mv_opp_status;
DROP INDEX IF EXISTS idx_mv_attributed_src;
DROP INDEX IF EXISTS idx_mv_ad_id;

-- 2. Eliminar la MV existente
DROP MATERIALIZED VIEW IF EXISTS mv_unified_attribution;

-- 3. Recrear con dual JOIN a dim_ads
CREATE MATERIALIZED VIEW mv_unified_attribution AS
SELECT
  c.contact_id,
  c.location_id,
  c.first_name,
  c.last_name,
  c.email,
  c.phone,

  -- ─── Resolución de nombre de anuncio (dual path) ─────────────────────────
  -- Prioridad: nombre directo GHL > dim_ads vía CTWA clicks > dim_ads vía
  -- campaign_id_first (CTWA) > dim_ads vía utm_content_first (UTM fb/ig)
  COALESCE(
    c.ad_name_first,
    d_ctwa.ad_name,
    d_camp.ad_name,
    d_utm.ad_name
  )                                                                           AS ad_name,

  -- ID del anuncio: CTWA click > campaign_id_first > utm_content_first
  COALESCE(ct.ad_id, c.campaign_id_first, c.utm_content_first)              AS ad_id,

  -- Adset y campaña (solo disponibles vía dim_ads — UTM no los expone con nombre)
  COALESCE(d_ctwa.adset_id,      d_camp.adset_id,      d_utm.adset_id)      AS adset_id,
  COALESCE(d_ctwa.adset_name,    d_camp.adset_name,    d_utm.adset_name)    AS adset_name,
  COALESCE(
    d_ctwa.campaign_id,   d_camp.campaign_id,   d_utm.campaign_id,
    ct.campaign_id,       c.campaign_id_first,  c.utm_campaign_first
  )                                                                           AS campaign_id,
  COALESCE(
    d_ctwa.campaign_name, d_camp.campaign_name, d_utm.campaign_name,
    ct.campaign_name,     c.utm_campaign_first
  )                                                                           AS campaign_name,

  -- ─── Fuente y medio normalizados ─────────────────────────────────────────
  CASE
    WHEN ct.id IS NOT NULL                    THEN 'whatsapp_ctwa'
    WHEN c.utm_source_first IN ('fb', 'ig')   THEN 'meta_utm'
    WHEN c.utm_source_first = 'Paid Social'   THEN 'paid_social'
    WHEN c.utm_source_first IS NOT NULL        THEN c.utm_source_first
    ELSE c.source
  END                                                                         AS attributed_source,

  CASE
    WHEN ct.id IS NOT NULL THEN 'paid_social_wa'
    ELSE c.utm_medium_first
  END                                                                         AS attributed_medium,

  -- Campos originales de atribución (para filtros avanzados)
  c.utm_source_first,
  c.utm_medium_first,
  c.utm_campaign_first,
  c.utm_content_first,
  c.campaign_id_first,

  -- ─── Oportunidad ─────────────────────────────────────────────────────────
  o.opportunity_id,
  o.pipeline_name,
  o.stage_name,
  o.status                                              AS opp_status,
  o.monetary_value,
  o.ghl_created_at                                      AS opp_created_at,

  -- ─── Conversación ────────────────────────────────────────────────────────
  cv.conversation_id,
  cv.channel_type,
  cv.first_reply_seconds,

  -- ─── IA ──────────────────────────────────────────────────────────────────
  cv.ai_intent,
  cv.ai_sentiment,
  c.ai_lead_score,

  -- ─── Timestamps ──────────────────────────────────────────────────────────
  c.ghl_created_at                                      AS contact_created_at,
  ct.clicked_at                                         AS ad_clicked_at,
  ct.ctwa_clid

FROM dim_contacts c

LEFT JOIN dim_opportunities o
  ON o.contact_id = c.contact_id AND o.is_current

LEFT JOIN dim_conversations cv
  ON cv.contact_id = c.contact_id AND cv.is_current

-- CTWA click tracking (vacío actualmente; se populará con webhook Meta Cloud API)
LEFT JOIN fact_ctwa_clicks ct
  ON ct.contact_id = c.contact_id

-- Path 1: via fact_ctwa_clicks → dim_ads (CTWA con click ID completo)
LEFT JOIN dim_ads d_ctwa
  ON d_ctwa.ad_id = ct.ad_id

-- Path 2: via campaign_id_first → dim_ads (CTWA via GHL attributions[].utmAdId)
LEFT JOIN dim_ads d_camp
  ON d_camp.ad_id = c.campaign_id_first

-- Path 3: via utm_content_first → dim_ads (UTM fb/ig: ?utm_content=<ad_id>)
LEFT JOIN dim_ads d_utm
  ON d_utm.ad_id = c.utm_content_first

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
CREATE INDEX idx_mv_contact_at     ON mv_unified_attribution(contact_created_at DESC);
