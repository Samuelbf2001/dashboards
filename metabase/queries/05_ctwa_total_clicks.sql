-- Descripcion: Total de clicks en anuncios CTWA de Meta capturados.
-- Tablas: fact_ctwa_clicks
-- Refresh rate: tiempo real

SELECT COUNT(*) AS total_clicks_ctwa
FROM fact_ctwa_clicks
WHERE 1=1
  [[ AND location_id = {{location_id}} ]]
  [[ AND clicked_at >= {{date_from}} ]]
  [[ AND clicked_at <= {{date_to}} ]]
