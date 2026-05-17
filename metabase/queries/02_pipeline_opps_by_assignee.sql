-- Descripcion: Oportunidades abiertas y valor en pipeline por asesor asignado.
-- Tablas: dim_opportunities
-- Refresh rate: cada hora

SELECT
  COALESCE(assigned_to_name, 'Sin asignar') AS asesor,
  COUNT(DISTINCT opportunity_id) AS oportunidades_abiertas,
  COALESCE(SUM(monetary_value), 0) AS valor_en_pipeline,
  ROUND(AVG(monetary_value), 2) AS valor_promedio
FROM dim_opportunities
WHERE is_current = TRUE
  AND status = 'open'
  [[ AND location_id = {{location_id}} ]]
  [[ AND pipeline_id = {{pipeline_id}} ]]
GROUP BY assigned_to_name
ORDER BY oportunidades_abiertas DESC
