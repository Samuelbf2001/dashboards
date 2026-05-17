-- Descripcion: Total de contactos activos (is_current = TRUE).
-- Tablas: dim_contacts
-- Refresh rate: tiempo real

SELECT COUNT(DISTINCT contact_id) AS total_contactos_activos
FROM dim_contacts
WHERE is_current = TRUE
  [[ AND location_id = {{location_id}} ]]
