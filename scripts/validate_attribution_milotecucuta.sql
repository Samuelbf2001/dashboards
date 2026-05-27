-- ─────────────────────────────────────────────────────────────────────────────
-- Validación de mv_unified_attribution para milotecucuta
-- location_id: 0IP2MEmSx0fpdVllDK5b
-- Solo SELECT — no escribe nada.
-- ─────────────────────────────────────────────────────────────────────────────

\set LOC '0IP2MEmSx0fpdVllDK5b'

-- ── Q1. Estado general del catálogo dim_ads ──────────────────────────────────
\echo '── Q1. dim_ads para milotecucuta'
SELECT
  COUNT(*)                                       AS total_ads,
  COUNT(DISTINCT campaign_id)                    AS campaigns,
  COUNT(DISTINCT adset_id)                       AS adsets,
  COUNT(*) FILTER (WHERE status='ACTIVE')        AS activos,
  MIN(synced_at)                                 AS primer_sync,
  MAX(synced_at)                                 AS ultimo_sync
FROM dim_ads
WHERE location_id = :'LOC';

-- ── Q2. Cobertura de atribución en contactos ─────────────────────────────────
\echo '── Q2. Cobertura de atribución (todos los contactos vs los con ad_name resuelto)'
SELECT
  COUNT(*)                                                          AS contactos_total,
  COUNT(ad_name)                                                    AS con_ad_name,
  ROUND(100.0 * COUNT(ad_name) / NULLIF(COUNT(*),0), 1)              AS pct_resueltos,
  COUNT(*) FILTER (
    WHERE ad_name IS NULL
      AND (campaign_id IS NOT NULL OR ad_id IS NOT NULL)
  )                                                                  AS atribuibles_sin_resolver,
  COUNT(*) FILTER (
    WHERE ad_name IS NULL
      AND campaign_id IS NULL AND ad_id IS NULL
  )                                                                  AS sin_atribucion_alguna
FROM mv_unified_attribution
WHERE location_id = :'LOC';

-- ── Q3. Origen del ad_name (qué COALESCE branch lo resuelve) ─────────────────
\echo '── Q3. ¿De dónde viene el ad_name? (debug del COALESCE de 5 niveles)'
SELECT
  COUNT(*) FILTER (WHERE m.ad_name IS NOT NULL)                                                        AS resueltos_total,
  COUNT(*) FILTER (WHERE c.ad_name_first IS NOT NULL)                                                  AS via_dim_contacts_ad_name_first,
  COUNT(*) FILTER (WHERE c.ad_name_first IS NULL AND c.campaign_id_first IS NOT NULL AND m.ad_name IS NOT NULL) AS via_campaign_id_first,
  COUNT(*) FILTER (WHERE c.ad_name_first IS NULL AND c.campaign_id_first IS NULL AND c.utm_content_first IS NOT NULL AND m.ad_name IS NOT NULL) AS via_utm_content_first
FROM mv_unified_attribution m
LEFT JOIN dim_contacts c ON c.contact_id = m.contact_id AND c.is_current = TRUE
WHERE m.location_id = :'LOC';

-- ── Q4. Distribución de fuente de tráfico ────────────────────────────────────
\echo '── Q4. Top 10 campañas por contactos atribuidos'
SELECT
  COALESCE(campaign_name, '(sin nombre)')        AS campana,
  COUNT(*)                                       AS contactos,
  COUNT(*) FILTER (WHERE ad_name IS NOT NULL)    AS con_ad_resuelto
FROM mv_unified_attribution
WHERE location_id = :'LOC'
GROUP BY campaign_name
ORDER BY contactos DESC
LIMIT 10;

-- ── Q5. Muestra de 15 contactos con atribución completa ──────────────────────
\echo '── Q5. Muestra (verificar manualmente vs GHL UI)'
SELECT
  contact_id,
  COALESCE(first_name||' '||last_name, email, phone) AS contacto,
  ad_name,
  campaign_name,
  ad_id
FROM mv_unified_attribution
WHERE location_id = :'LOC'
  AND ad_name IS NOT NULL
ORDER BY contact_id DESC
LIMIT 15;

-- ── Q6. Muestra de 10 contactos atribuibles SIN resolver (deuda técnica) ─────
\echo '── Q6. Contactos con campaign_id pero sin ad_name resuelto (qué hay que arreglar)'
SELECT
  m.contact_id,
  c.campaign_id_first,
  c.utm_content_first,
  c.ad_name_first
FROM mv_unified_attribution m
JOIN dim_contacts c USING (contact_id)
WHERE m.location_id = :'LOC'
  AND m.ad_name IS NULL
  AND (c.campaign_id_first IS NOT NULL OR c.utm_content_first IS NOT NULL)
LIMIT 10;

-- ── Q7. Estado del refresh de la MV ──────────────────────────────────────────
\echo '── Q7. Última vez que se refrescó la MV (pg_stat_all_tables)'
SELECT
  schemaname,
  relname,
  last_vacuum,
  last_autovacuum,
  last_analyze,
  last_autoanalyze
FROM pg_stat_all_tables
WHERE relname = 'mv_unified_attribution';

-- ── Q8. Jobs de pg_cron registrados ──────────────────────────────────────────
\echo '── Q8. Jobs de pg_cron'
SELECT jobid, schedule, command, active FROM cron.job;
