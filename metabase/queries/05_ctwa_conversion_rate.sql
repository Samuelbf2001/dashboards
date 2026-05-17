-- Descripcion: Tasa de conversion de leads CTWA a oportunidades won.
--   = oportunidades won con origen CTWA / total leads CTWA correlacionados
-- Tablas: fact_ctwa_clicks JOIN dim_opportunities
-- Refresh rate: cada hora

SELECT
  COUNT(DISTINCT ct.contact_id) AS leads_ctwa,
  COUNT(DISTINCT CASE WHEN o.status = 'won' THEN ct.contact_id END) AS won,
  ROUND(
    100.0 * COUNT(DISTINCT CASE WHEN o.status = 'won' THEN ct.contact_id END)
    / NULLIF(COUNT(DISTINCT ct.contact_id), 0),
    2
  ) AS tasa_conversion_ctwa_pct
FROM fact_ctwa_clicks ct
LEFT JOIN dim_opportunities o
  ON o.opportunity_id = ct.converted_to_opp_id
  AND o.is_current = TRUE
WHERE ct.contact_id IS NOT NULL
  [[ AND ct.location_id = {{location_id}} ]]
  [[ AND ct.clicked_at >= {{date_from}} ]]
  [[ AND ct.clicked_at <= {{date_to}} ]]
