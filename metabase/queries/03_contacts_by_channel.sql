-- Descripcion: Distribucion de contactos por canal de primera conversacion (channel_type).
-- Tablas: mv_unified_attribution
-- Refresh rate: cada hora

SELECT
  COALESCE(channel_type, 'sin_conversacion') AS canal,
  COUNT(DISTINCT contact_id) AS total
FROM mv_unified_attribution
WHERE 1=1
  [[ AND location_id = {{location_id}} ]]
  [[ AND contact_created_at >= {{date_from}} ]]
  [[ AND contact_created_at <= {{date_to}} ]]
GROUP BY channel_type
ORDER BY total DESC
