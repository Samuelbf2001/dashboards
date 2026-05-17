-- Descripcion: Tasa de conversion global = oportunidades won / total oportunidades x 100.
-- Tablas: mv_unified_attribution
-- Refresh rate: cada hora

SELECT
  ROUND(
    100.0 * COUNT(DISTINCT CASE WHEN opp_status = 'won' THEN opportunity_id END)
    / NULLIF(COUNT(DISTINCT opportunity_id), 0),
    2
  ) AS conversion_rate_pct
FROM mv_unified_attribution
WHERE opportunity_id IS NOT NULL
  [[ AND location_id = {{location_id}} ]]
  [[ AND opp_created_at >= {{date_from}} ]]
  [[ AND opp_created_at <= {{date_to}} ]]
