-- Descripcion: Leads (clicks CTWA correlacionados con contact_id) por campana Meta.
-- Tablas: fact_ctwa_clicks
-- Refresh rate: cada hora

SELECT
  COALESCE(campaign_name, 'Sin nombre') AS campana,
  campaign_id,
  COUNT(*) AS total_clicks,
  COUNT(CASE WHEN contact_id IS NOT NULL THEN 1 END) AS leads_correlacionados
FROM fact_ctwa_clicks
WHERE 1=1
  [[ AND location_id = {{location_id}} ]]
  [[ AND clicked_at >= {{date_from}} ]]
  [[ AND clicked_at <= {{date_to}} ]]
GROUP BY campaign_name, campaign_id
ORDER BY leads_correlacionados DESC
