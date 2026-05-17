-- Descripcion: Total de oportunidades con status=open (version actual).
-- Tablas: mv_unified_attribution
-- Refresh rate: cada hora

SELECT COUNT(DISTINCT opportunity_id) AS oportunidades_abiertas
FROM mv_unified_attribution
WHERE opp_status = 'open'
  AND opportunity_id IS NOT NULL
  [[ AND location_id = {{location_id}} ]]
