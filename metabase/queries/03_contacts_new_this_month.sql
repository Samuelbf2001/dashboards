-- Descripcion: Contactos creados en el mes calendario actual.
-- Tablas: dim_contacts
-- Refresh rate: tiempo real

SELECT COUNT(DISTINCT contact_id) AS nuevos_este_mes
FROM dim_contacts
WHERE is_current = TRUE
  AND DATE_TRUNC('month', ghl_created_at) = DATE_TRUNC('month', CURRENT_DATE)
  [[ AND location_id = {{location_id}} ]]
