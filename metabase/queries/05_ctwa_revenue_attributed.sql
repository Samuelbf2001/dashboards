-- Descripcion: Revenue total atribuido a leads CTWA (oportunidades won cuyo origen es un click CTWA).
-- Tablas: fact_ctwa_clicks JOIN dim_opportunities
-- Refresh rate: cada hora

SELECT COALESCE(SUM(o.monetary_value), 0) AS revenue_atribuido_ctwa
FROM fact_ctwa_clicks ct
JOIN dim_opportunities o
  ON o.opportunity_id = ct.converted_to_opp_id
  AND o.is_current = TRUE
WHERE o.status = 'won'
  [[ AND ct.location_id = {{location_id}} ]]
  [[ AND ct.clicked_at >= {{date_from}} ]]
  [[ AND ct.clicked_at <= {{date_to}} ]]
