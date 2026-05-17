-- Descripcion: Forecast simple de revenue por mes de close_date para oportunidades abiertas.
-- Tablas: dim_opportunities
-- Refresh rate: cada hora

SELECT
  DATE_TRUNC('month', close_date) AS mes_cierre,
  COUNT(DISTINCT opportunity_id) AS oportunidades,
  COALESCE(SUM(monetary_value), 0) AS revenue_esperado
FROM dim_opportunities
WHERE is_current = TRUE
  AND status = 'open'
  AND close_date IS NOT NULL
  AND close_date >= CURRENT_DATE
  [[ AND location_id = {{location_id}} ]]
  [[ AND pipeline_id = {{pipeline_id}} ]]
GROUP BY DATE_TRUNC('month', close_date)
ORDER BY mes_cierre ASC
LIMIT 12
