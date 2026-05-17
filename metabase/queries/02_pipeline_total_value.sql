-- Descripcion: Valor total monetario de oportunidades abiertas en el pipeline.
-- Tablas: dim_opportunities
-- Refresh rate: cada hora

SELECT COALESCE(SUM(monetary_value), 0) AS valor_total_pipeline
FROM dim_opportunities
WHERE is_current = TRUE
  AND status = 'open'
  [[ AND location_id = {{location_id}} ]]
  [[ AND pipeline_id = {{pipeline_id}} ]]
