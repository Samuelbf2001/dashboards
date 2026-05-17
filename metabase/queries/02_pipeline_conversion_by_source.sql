-- Descripcion: Tasa de conversion por fuente UTM atribuida. JOIN a mv_unified_attribution para la fuente.
-- Tablas: mv_unified_attribution
-- Refresh rate: cada hora

SELECT
  COALESCE(attributed_source, 'sin_fuente') AS fuente,
  COUNT(DISTINCT opportunity_id) AS total_opps,
  COUNT(DISTINCT CASE WHEN opp_status = 'won' THEN opportunity_id END) AS won,
  ROUND(
    100.0 * COUNT(DISTINCT CASE WHEN opp_status = 'won' THEN opportunity_id END)
    / NULLIF(COUNT(DISTINCT CASE WHEN opp_status IN ('won','lost','abandoned') THEN opportunity_id END), 0),
    2
  ) AS conversion_rate_pct
FROM mv_unified_attribution
WHERE opportunity_id IS NOT NULL
  [[ AND location_id = {{location_id}} ]]
  [[ AND opp_created_at >= {{date_from}} ]]
  [[ AND opp_created_at <= {{date_to}} ]]
GROUP BY attributed_source
ORDER BY total_opps DESC
LIMIT 20
