-- Descripcion: Revenue total de oportunidades ganadas (status=won), con filtro por location y rango de fechas.
-- Tablas: mv_unified_attribution
-- Refresh rate: cada hora

SELECT COALESCE(SUM(monetary_value), 0) AS revenue_ganado
FROM mv_unified_attribution
WHERE opp_status = 'won'
  AND opportunity_id IS NOT NULL
  [[ AND location_id = {{location_id}} ]]
  [[ AND opp_created_at >= {{date_from}} ]]
  [[ AND opp_created_at <= {{date_to}} ]]
