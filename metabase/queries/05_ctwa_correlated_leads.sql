-- Descripcion: Clicks CTWA que ya fueron correlacionados con un contact_id en GHL via WF-11.
-- Tablas: fact_ctwa_clicks
-- Refresh rate: tiempo real

SELECT COUNT(*) AS leads_correlacionados
FROM fact_ctwa_clicks
WHERE contact_id IS NOT NULL
  [[ AND location_id = {{location_id}} ]]
  [[ AND clicked_at >= {{date_from}} ]]
  [[ AND clicked_at <= {{date_to}} ]]
