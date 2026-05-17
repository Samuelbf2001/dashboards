-- Descripcion: ROAS = revenue atribuido / lifetime_spend de dim_ads agrupado por campana.
--   Proxy de retorno sobre inversion publicitaria. lifetime_spend proviene de dim_ads.
-- Tablas: fact_ctwa_clicks JOIN dim_opportunities JOIN dim_ads
-- Refresh rate: cada hora

SELECT
  ct.campaign_name AS campana,
  ct.campaign_id,
  COALESCE(SUM(o.monetary_value), 0) AS revenue_atribuido,
  COALESCE(MAX(da.lifetime_spend), 0) AS gasto_total,
  ROUND(
    COALESCE(SUM(o.monetary_value), 0)
    / NULLIF(MAX(da.lifetime_spend), 0),
    2
  ) AS roas
FROM fact_ctwa_clicks ct
LEFT JOIN dim_opportunities o
  ON o.opportunity_id = ct.converted_to_opp_id
  AND o.is_current = TRUE
  AND o.status = 'won'
LEFT JOIN dim_ads da
  ON da.ad_id = ct.ad_id
WHERE 1=1
  [[ AND ct.location_id = {{location_id}} ]]
  [[ AND ct.campaign_id = {{campaign_id}} ]]
GROUP BY ct.campaign_name, ct.campaign_id
ORDER BY roas DESC NULLS LAST
