-- Descripcion: Tiempo promedio en segundos entre el click en el anuncio CTWA y el primer mensaje
--   de WhatsApp del usuario. Mide la friccion del flujo ad -> chat.
-- Tablas: fact_ctwa_clicks
-- Refresh rate: cada hora

SELECT
  ROUND(AVG(
    EXTRACT(EPOCH FROM (first_message_at - clicked_at))
  ), 0) AS seg_click_a_mensaje,
  ROUND(AVG(
    EXTRACT(EPOCH FROM (first_message_at - clicked_at))
  ) / 60.0, 1) AS min_click_a_mensaje
FROM fact_ctwa_clicks
WHERE first_message_at IS NOT NULL
  AND clicked_at IS NOT NULL
  AND first_message_at > clicked_at
  [[ AND location_id = {{location_id}} ]]
  [[ AND campaign_id = {{campaign_id}} ]]
