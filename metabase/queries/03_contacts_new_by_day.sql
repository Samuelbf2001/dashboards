-- Descripcion: Nuevos contactos por dia (primera version SCD2 = is_current con valid_from minimo).
-- Tablas: dim_contacts
-- Refresh rate: tiempo real

SELECT
  DATE_TRUNC('day', ghl_created_at) AS dia,
  COUNT(DISTINCT contact_id) AS nuevos_contactos
FROM dim_contacts
WHERE is_current = TRUE
  AND ghl_created_at IS NOT NULL
  [[ AND location_id = {{location_id}} ]]
  [[ AND ghl_created_at >= {{date_from}} ]]
  [[ AND ghl_created_at <= {{date_to}} ]]
GROUP BY DATE_TRUNC('day', ghl_created_at)
ORDER BY dia ASC
