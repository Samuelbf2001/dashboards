-- Descripcion: No-show rate por canal de la conversacion que origino la cita.
--   JOIN a dim_conversations para obtener el canal de origen.
-- Tablas: ghl_appointments JOIN dim_conversations
-- Refresh rate: cada hora

SELECT
  COALESCE(cv.channel_type, 'desconocido') AS canal_origen,
  COUNT(*) AS total_citas,
  COUNT(CASE WHEN a.status IN ('no_show','noshow','no-show') THEN 1 END) AS no_shows,
  ROUND(
    100.0 * COUNT(CASE WHEN a.status IN ('no_show','noshow','no-show') THEN 1 END)
    / NULLIF(COUNT(*), 0),
    1
  ) AS noshow_rate_pct
FROM ghl_appointments a
LEFT JOIN dim_conversations cv
  ON cv.contact_id = a.contact_id
  AND cv.is_current = TRUE
WHERE a.start_time < NOW()
  [[ AND a.location_id = {{location_id}} ]]
  [[ AND a.start_time >= {{date_from}} ]]
  [[ AND a.start_time <= {{date_to}} ]]
GROUP BY cv.channel_type
ORDER BY noshow_rate_pct DESC
