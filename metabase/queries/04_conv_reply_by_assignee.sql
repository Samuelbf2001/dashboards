-- Descripcion: Avg first reply time en minutos por asesor asignado a la conversacion.
-- Tablas: dim_conversations
-- Refresh rate: tiempo real

SELECT
  COALESCE(assigned_user_name, 'Sin asignar') AS asesor,
  ROUND(AVG(first_reply_seconds) / 60.0, 1) AS avg_first_reply_min,
  COUNT(DISTINCT conversation_id) AS total_conversaciones
FROM dim_conversations
WHERE is_current = TRUE
  AND first_reply_seconds IS NOT NULL
  AND first_reply_seconds > 0
  [[ AND location_id = {{location_id}} ]]
  [[ AND ghl_created_at >= {{date_from}} ]]
  [[ AND ghl_created_at <= {{date_to}} ]]
GROUP BY assigned_user_name
ORDER BY avg_first_reply_min ASC
