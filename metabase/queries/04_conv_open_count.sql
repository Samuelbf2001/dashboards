-- Descripcion: Conversaciones actualmente abiertas (status=open, version actual).
-- Tablas: dim_conversations
-- Refresh rate: tiempo real

SELECT COUNT(DISTINCT conversation_id) AS conversaciones_abiertas
FROM dim_conversations
WHERE is_current = TRUE
  AND status = 'open'
  [[ AND location_id = {{location_id}} ]]
