-- Descripcion: Top 5 fuentes UTM (utm_source_first) por volumen de contactos.
-- Tablas: mv_unified_attribution
-- Refresh rate: cada hora

SELECT
  COALESCE(attributed_source, 'sin_fuente') AS fuente,
  COUNT(DISTINCT contact_id) AS total_contactos
FROM mv_unified_attribution
WHERE 1=1
  [[ AND location_id = {{location_id}} ]]
  [[ AND contact_created_at >= {{date_from}} ]]
  [[ AND contact_created_at <= {{date_to}} ]]
GROUP BY attributed_source
ORDER BY total_contactos DESC
LIMIT 5
