-- Descripcion: Funnel de oportunidades agrupado por etapa (stage_order) para visualizacion de embudo.
-- Tablas: dim_opportunities JOIN dim_pipelines
-- Refresh rate: tiempo real via JOIN directo (sin MV)

SELECT
  o.stage_name,
  p.stage_order,
  COUNT(DISTINCT o.opportunity_id) AS total_opps,
  COALESCE(SUM(o.monetary_value), 0) AS valor_en_etapa
FROM dim_opportunities o
JOIN dim_pipelines p
  ON p.pipeline_id = o.pipeline_id
  AND p.stage_id = o.pipeline_stage_id
WHERE o.is_current = TRUE
  AND o.status = 'open'
  [[ AND o.location_id = {{location_id}} ]]
  [[ AND o.pipeline_id = {{pipeline_id}} ]]
  [[ AND o.ghl_created_at >= {{date_from}} ]]
  [[ AND o.ghl_created_at <= {{date_to}} ]]
GROUP BY o.stage_name, p.stage_order
ORDER BY p.stage_order ASC
