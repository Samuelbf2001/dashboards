-- Descripcion: Tiempo promedio de primera respuesta en segundos (first_reply_seconds).
--   KPI principal de velocidad de respuesta al lead.
-- Tablas: dim_conversations
-- Refresh rate: tiempo real

SELECT
  ROUND(AVG(first_reply_seconds), 0) AS avg_first_reply_seg,
  ROUND(AVG(first_reply_seconds) / 60.0, 1) AS avg_first_reply_min
FROM dim_conversations
WHERE is_current = TRUE
  AND first_reply_seconds IS NOT NULL
  AND first_reply_seconds > 0
  [[ AND location_id = {{location_id}} ]]
  [[ AND channel_type = {{channel_type}} ]]
  [[ AND ghl_created_at >= {{date_from}} ]]
  [[ AND ghl_created_at <= {{date_to}} ]]
