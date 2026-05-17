-- Descripcion: Tiempo promedio en cada etapa del pipeline en dias (velocity).
-- Tablas: fact_opp_stage_history JOIN dim_pipelines
-- Refresh rate: tiempo real

SELECT
  h.to_stage_name AS etapa,
  p.stage_order,
  ROUND(AVG(h.time_in_prev_stage_sec) / 86400.0, 1) AS dias_promedio_en_etapa,
  COUNT(*) AS total_movimientos
FROM fact_opp_stage_history h
JOIN dim_pipelines p
  ON p.pipeline_id = h.pipeline_id
  AND p.stage_id = h.to_stage_id
WHERE h.time_in_prev_stage_sec IS NOT NULL
  AND h.time_in_prev_stage_sec > 0
  [[ AND h.location_id = {{location_id}} ]]
  [[ AND h.pipeline_id = {{pipeline_id}} ]]
GROUP BY h.to_stage_name, p.stage_order
ORDER BY p.stage_order ASC
