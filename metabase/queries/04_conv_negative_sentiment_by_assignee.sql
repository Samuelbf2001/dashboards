-- Descripcion: Ratio de conversaciones con sentimiento negativo por asesor.
--   Permite identificar asesores con alta tasa de interacciones negativas.
-- Tablas: dim_conversations
-- Refresh rate: cada hora

SELECT
  COALESCE(assigned_user_name, 'Sin asignar') AS asesor,
  COUNT(DISTINCT conversation_id) AS total_conversaciones,
  COUNT(DISTINCT CASE WHEN ai_sentiment = 'negative' THEN conversation_id END) AS negativas,
  ROUND(
    100.0 * COUNT(DISTINCT CASE WHEN ai_sentiment = 'negative' THEN conversation_id END)
    / NULLIF(COUNT(DISTINCT conversation_id), 0),
    1
  ) AS ratio_negativo_pct
FROM dim_conversations
WHERE is_current = TRUE
  [[ AND location_id = {{location_id}} ]]
  [[ AND ghl_created_at >= {{date_from}} ]]
  [[ AND ghl_created_at <= {{date_to}} ]]
GROUP BY assigned_user_name
HAVING COUNT(DISTINCT conversation_id) >= 5
ORDER BY ratio_negativo_pct DESC
