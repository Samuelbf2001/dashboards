-- Descripcion: Conteo de oportunidades abiertas actualmente.
-- Tablas: dim_opportunities
-- Refresh rate: cada hora

SELECT COUNT(DISTINCT opportunity_id) AS oportunidades_abiertas
FROM dim_opportunities
WHERE is_current = TRUE
  AND status = 'open'
  [[ AND location_id = {{location_id}} ]]
  [[ AND pipeline_id = {{pipeline_id}} ]]
