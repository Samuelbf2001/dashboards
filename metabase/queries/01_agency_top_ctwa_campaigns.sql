-- Descripcion: Top 5 campanas CTWA por volumen de leads (solo registros con ctwa_clid no nulo).
-- Tablas: mv_unified_attribution
-- Refresh rate: cada hora

SELECT
  COALESCE(campaign_name, 'Sin nombre') AS campana,
  COUNT(DISTINCT contact_id) AS leads_ctwa
FROM mv_unified_attribution
WHERE ctwa_clid IS NOT NULL
  [[ AND location_id = {{location_id}} ]]
  [[ AND contact_created_at >= {{date_from}} ]]
  [[ AND contact_created_at <= {{date_to}} ]]
GROUP BY campaign_name
ORDER BY leads_ctwa DESC
LIMIT 5
