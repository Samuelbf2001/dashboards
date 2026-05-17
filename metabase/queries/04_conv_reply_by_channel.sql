-- Descripcion: Avg first reply time en minutos por canal (WHATSAPP, SMS, EMAIL, etc.).
-- Tablas: dim_conversations
-- Refresh rate: tiempo real

SELECT
  channel_type AS canal,
  ROUND(AVG(first_reply_seconds) / 60.0, 1) AS avg_first_reply_min,
  COUNT(DISTINCT conversation_id) AS total_conversaciones
FROM dim_conversations
WHERE is_current = TRUE
  AND first_reply_seconds IS NOT NULL
  AND first_reply_seconds > 0
  [[ AND location_id = {{location_id}} ]]
  [[ AND ghl_created_at >= {{date_from}} ]]
  [[ AND ghl_created_at <= {{date_to}} ]]
GROUP BY channel_type
ORDER BY avg_first_reply_min ASC
