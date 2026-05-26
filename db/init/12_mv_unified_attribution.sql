-- ─────────────────────────────────────────────────────────────────────────────
-- 12_mv_unified_attribution.sql — Vista Materializada de Atribución Unificada
-- Consolida contacts + opportunities + conversations + CTWA en una sola fila
-- por par contacto-oportunidad. Es el origen principal de los dashboards de Metabase.
-- Se refresca automáticamente cada hora con pg_cron (13_pg_cron.sql).
--
-- MODELO DE ATRIBUCIÓN:
--   La fuente de verdad es dim_contacts. Oportunidades, agendas y conversaciones
--   heredan atribución del contacto asociado vía contact_id JOIN.
--
--   Hay dos rutas de atribución Meta:
--     Path A (CTWA): campaign_id_first = GHL attributions[].utmAdId (Meta ad ID)
--     Path B (UTM):  utm_content_first = ?utm_content= URL param   (Meta ad ID)
--
--   Jerarquía COALESCE para ad_name:
--     1. ad_name_first  — GHL popula directamente (CTWA con nombre)
--     2. d_ctwa.ad_name — via fact_ctwa_clicks.ad_id (preparado para datos futuros)
--     3. d_camp.ad_name — via campaign_id_first (CTWA sin nombre directo)
--     4. d_utm.ad_name  — via utm_content_first (UTM fb/ig)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_unified_attribution AS
SELECT
  c.contact_id,
  c.location_id,
  c.first_name,
  c.last_name,
  c.email,
  c.phone,

  -- ─── Resolución de nombre de anuncio (dual path) ─────────────────────────
  COALESCE(
    c.ad_name_first,
    d_ctwa.ad_name,
    d_camp.ad_name,
    d_utm.ad_name
  )                                                                           AS ad_name,

  COALESCE(ct.ad_id, c.campaign_id_first, c.utm_content_first)              AS ad_id,

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

  -- Campos originales (para filtros avanzados en Metabase)
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

-- ─── Índice UNIQUE requerido para REFRESH CONCURRENTLY ───────────────────────
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_unique_row
  ON mv_unified_attribution(
    contact_id,
    COALESCE(opportunity_id, ''),
    COALESCE(ctwa_clid, '')
  );

-- ─── Índices de rendimiento ───────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_mv_location       ON mv_unified_attribution(location_id);
CREATE INDEX IF NOT EXISTS idx_mv_campaign       ON mv_unified_attribution(campaign_name);
CREATE INDEX IF NOT EXISTS idx_mv_opp_status     ON mv_unified_attribution(opp_status);
CREATE INDEX IF NOT EXISTS idx_mv_attributed_src ON mv_unified_attribution(attributed_source);
CREATE INDEX IF NOT EXISTS idx_mv_ad_id          ON mv_unified_attribution(ad_id);
CREATE INDEX IF NOT EXISTS idx_mv_contact_at     ON mv_unified_attribution(contact_created_at DESC);
