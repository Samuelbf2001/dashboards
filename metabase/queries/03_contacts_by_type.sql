-- Descripcion: Distribucion de contactos por contact_type (lead, client, other).
-- Tablas: dim_contacts
-- Refresh rate: cada hora

SELECT
  COALESCE(contact_type, 'sin_tipo') AS tipo,
  COUNT(DISTINCT contact_id) AS total
FROM dim_contacts
WHERE is_current = TRUE
  [[ AND location_id = {{location_id}} ]]
GROUP BY contact_type
ORDER BY total DESC
