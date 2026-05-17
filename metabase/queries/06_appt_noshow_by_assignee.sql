-- Descripcion: Tasa de no-show por asesor para identificar patrones de inasistencia.
-- Tablas: ghl_appointments
-- Refresh rate: tiempo real

SELECT
  COALESCE(assigned_user_name, 'Sin asignar') AS asesor,
  COUNT(*) AS total_pasadas,
  COUNT(CASE WHEN status IN ('no_show','noshow','no-show') THEN 1 END) AS no_shows,
  ROUND(
    100.0 * COUNT(CASE WHEN status IN ('no_show','noshow','no-show') THEN 1 END)
    / NULLIF(COUNT(*), 0),
    1
  ) AS noshow_rate_pct
FROM ghl_appointments
WHERE start_time < NOW()
  [[ AND location_id = {{location_id}} ]]
  [[ AND start_time >= {{date_from}} ]]
  [[ AND start_time <= {{date_to}} ]]
GROUP BY assigned_user_name
HAVING COUNT(*) >= 3
ORDER BY noshow_rate_pct DESC
