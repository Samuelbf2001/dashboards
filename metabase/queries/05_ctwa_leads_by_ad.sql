-- Descripcion: Leads por ad_id (granularidad de anuncio individual).
-- Tablas: fact_ctwa_clicks
-- Refresh rate: cada hora

SELECT
  COALESCE(ad_name, 'Sin nombre') AS anuncio,
  ad_id,
  COUNT(*) AS total_clicks,
  COUNT(CASE WHEN contact_id IS NOT NULL THEN 1 END) AS leads_correlacionados
FROM fact_ctwa_clicks
WHERE 1=1
  [[ AND location_id = {{location_id}} ]]
  [[ AND campaign_id = {{campaign_id}} ]]
  [[ AND clicked_at >= {{date_from}} ]]
  [[ AND clicked_at <= {{date_to}} ]]
GROUP BY ad_name, ad_id
ORDER BY leads_correlacionados DESC
LIMIT 20
