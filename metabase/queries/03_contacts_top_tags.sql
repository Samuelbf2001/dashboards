-- Descripcion: Top tags de contactos activos usando UNNEST sobre el array tags[].
-- Tablas: dim_contacts
-- Refresh rate: cada hora

SELECT
  tag,
  COUNT(DISTINCT contact_id) AS contactos_con_tag
FROM dim_contacts,
  UNNEST(tags) AS tag
WHERE is_current = TRUE
  AND tags IS NOT NULL
  [[ AND location_id = {{location_id}} ]]
GROUP BY tag
ORDER BY contactos_con_tag DESC
LIMIT 20
