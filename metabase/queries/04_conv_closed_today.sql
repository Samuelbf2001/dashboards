-- Descripcion: Conversaciones cerradas hoy (cualquier version con status=closed actualizado hoy).
-- Tablas: dim_conversations
-- Refresh rate: tiempo real

SELECT COUNT(DISTINCT conversation_id) AS cerradas_hoy
FROM dim_conversations
WHERE is_current = TRUE
  AND status = 'closed'
  AND DATE_TRUNC('day', synced_at) = CURRENT_DATE
  [[ AND location_id = {{location_id}} ]]
