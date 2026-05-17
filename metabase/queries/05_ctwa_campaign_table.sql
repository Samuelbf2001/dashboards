-- Descripcion: Tabla resumen de todas las campanas CTWA con metricas clave.
-- Tablas: fact_ctwa_clicks JOIN dim_opportunities JOIN dim_ads
-- Refresh rate: cada hora

SELECT
  ct.campaign_name AS campana,
  ct.campaign_id,
  COUNT(DISTINCT ct.ctwa_clid) AS clicks,
  COUNT(DISTINCT ct.contact_id) AS leads_correlacionados,
  COUNT(DISTINCT CASE WHEN o.status = 'won' THEN ct.contact_id END) AS conversiones,
  ROUND(
    100.0 * COUNT(DISTINCT CASE WHEN o.status = 'won' THEN ct.contact_id END)
    / NULLIF(COUNT(DISTINCT ct.contact_id), 0), 1
  ) AS conv_rate_pct,
  COALESCE(SUM(CASE WHEN o.status = 'won' THEN o.monetary_value END), 0) AS revenue,
  COALESCE(MAX(da.lifetime_spend), 0) AS gasto,
  ROUND(
    COALESCE(SUM(CASE WHEN o.status = 'won' THEN o.monetary_value END), 0)
    / NULLIF(MAX(da.lifetime_spend), 0), 2
  ) AS roas
FROM fact_ctwa_clicks ct
LEFT JOIN dim_opportunities o
  ON o.opportunity_id = ct.converted_to_opp_id AND o.is_current = TRUE
LEFT JOIN dim_ads da
  ON da.ad_id = ct.ad_id
WHERE 1=1
  [[ AND ct.location_id = {{location_id}} ]]
  [[ AND ct.clicked_at >= {{date_from}} ]]
  [[ AND ct.clicked_at <= {{date_to}} ]]
GROUP BY ct.campaign_name, ct.campaign_id
ORDER BY revenue DESC NULLS LAST
