-- Descripcion: Distribucion de conversaciones por canal.
-- Tablas: dim_conversations
-- Refresh rate: tiempo real

SELECT
  COALESCE(channel_type, 'desconocido') AS canal,
  COUNT(DISTINCT conversation_id) AS total
FROM dim_conversations
WHERE is_current = TRUE
  [[ AND location_id = {{location_id}} ]]
  [[ AND ghl_created_at >= {{date_from}} ]]
  [[ AND ghl_created_at <= {{date_to}} ]]
GROUP BY channel_type
ORDER BY total DESC
