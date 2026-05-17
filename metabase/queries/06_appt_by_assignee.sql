-- Descripcion: Citas agendadas por asesor asignado.
-- Tablas: ghl_appointments
-- Refresh rate: tiempo real

SELECT
  COALESCE(assigned_user_name, 'Sin asignar') AS asesor,
  COUNT(*) AS total_citas,
  COUNT(CASE WHEN status IN ('showed','completed','attended') THEN 1 END) AS shows,
  COUNT(CASE WHEN status IN ('no_show','noshow','no-show') THEN 1 END) AS no_shows
FROM ghl_appointments
WHERE 1=1
  [[ AND location_id = {{location_id}} ]]
  [[ AND start_time >= {{date_from}} ]]
  [[ AND start_time <= {{date_to}} ]]
GROUP BY assigned_user_name
ORDER BY total_citas DESC
