-- Descripcion: Distribucion de contactos activos por fuente UTM del primer toque.
-- Tablas: dim_contacts
-- Refresh rate: cada hora

SELECT
  COALESCE(utm_source_first, 'organico/directo') AS fuente_utm,
  COUNT(DISTINCT contact_id) AS total
FROM dim_contacts
WHERE is_current = TRUE
  [[ AND location_id = {{location_id}} ]]
  [[ AND ghl_created_at >= {{date_from}} ]]
  [[ AND ghl_created_at <= {{date_to}} ]]
GROUP BY utm_source_first
ORDER BY total DESC
LIMIT 15
