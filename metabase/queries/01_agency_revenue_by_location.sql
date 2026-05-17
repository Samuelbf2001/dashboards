-- Descripcion: Revenue ganado por location_id. Vista multi-cliente para admin Sixteam.
-- Tablas: mv_unified_attribution
-- Refresh rate: cada hora

SELECT
  location_id,
  COALESCE(SUM(monetary_value), 0) AS revenue_ganado
FROM mv_unified_attribution
WHERE opp_status = 'won'
  AND opportunity_id IS NOT NULL
  [[ AND opp_created_at >= {{date_from}} ]]
  [[ AND opp_created_at <= {{date_to}} ]]
GROUP BY location_id
ORDER BY revenue_ganado DESC
