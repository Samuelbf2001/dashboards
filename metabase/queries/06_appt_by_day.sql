-- Descripcion: Citas agendadas por dia para ver tendencia temporal.
-- Tablas: ghl_appointments
-- Refresh rate: tiempo real

SELECT
  DATE_TRUNC('day', start_time) AS dia,
  COUNT(*) AS total_citas,
  COUNT(CASE WHEN status IN ('showed','completed','attended') THEN 1 END) AS shows,
  COUNT(CASE WHEN status IN ('no_show','noshow','no-show') THEN 1 END) AS no_shows
FROM ghl_appointments
WHERE 1=1
  [[ AND location_id = {{location_id}} ]]
  [[ AND start_time >= {{date_from}} ]]
  [[ AND start_time <= {{date_to}} ]]
GROUP BY DATE_TRUNC('day', start_time)
ORDER BY dia ASC
