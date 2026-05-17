-- Descripcion: Revenue ganado atribuido a cada campana CTWA.
-- Tablas: fact_ctwa_clicks JOIN dim_opportunities
-- Refresh rate: cada hora

SELECT
  COALESCE(ct.campaign_name, 'Sin nombre') AS campana,
  COUNT(DISTINCT ct.contact_id) AS leads,
  COUNT(DISTINCT CASE WHEN o.status = 'won' THEN ct.contact_id END) AS conversiones,
  COALESCE(SUM(CASE WHEN o.status = 'won' THEN o.monetary_value END), 0) AS revenue_atribuido
FROM fact_ctwa_clicks ct
LEFT JOIN dim_opportunities o
  ON o.opportunity_id = ct.converted_to_opp_id
  AND o.is_current = TRUE
WHERE ct.contact_id IS NOT NULL
  [[ AND ct.location_id = {{location_id}} ]]
  [[ AND ct.clicked_at >= {{date_from}} ]]
  [[ AND ct.clicked_at <= {{date_to}} ]]
GROUP BY ct.campaign_name
ORDER BY revenue_atribuido DESC
