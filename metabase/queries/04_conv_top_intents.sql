-- Descripcion: Top intents de conversaciones entrantes (ai_intent) para identificar motivos de contacto.
--   purchase_intent = oportunidad de venta; support = atencion post-venta.
-- Tablas: dim_conversations
-- Refresh rate: cada hora

SELECT
  COALESCE(ai_intent, 'sin_clasificar') AS intent,
  COUNT(DISTINCT conversation_id) AS total,
  ROUND(
    100.0 * COUNT(DISTINCT conversation_id) / NULLIF(SUM(COUNT(DISTINCT conversation_id)) OVER (), 0),
    1
  ) AS porcentaje
FROM dim_conversations
WHERE is_current = TRUE
  [[ AND location_id = {{location_id}} ]]
  [[ AND ghl_created_at >= {{date_from}} ]]
  [[ AND ghl_created_at <= {{date_to}} ]]
GROUP BY ai_intent
ORDER BY total DESC
