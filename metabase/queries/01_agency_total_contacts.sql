-- Descripcion: Total de contactos activos (is_current=TRUE) con filtro opcional por location_id y rango de fechas.
-- Tablas: mv_unified_attribution
-- Refresh rate: cada hora (al refrescar la MV)

SELECT COUNT(DISTINCT contact_id) AS total_contactos
FROM mv_unified_attribution
WHERE 1=1
  [[ AND location_id = {{location_id}} ]]
  [[ AND contact_created_at >= {{date_from}} ]]
  [[ AND contact_created_at <= {{date_to}} ]]
