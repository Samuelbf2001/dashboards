-- Descripcion: Tasa de conversion won/(won+lost+abandoned) en porcentaje.
-- Tablas: dim_opportunities
-- Refresh rate: cada hora
-- Nota: excluye status=open porque son oportunidades no resueltas aun.

SELECT
  ROUND(
    100.0 * COUNT(DISTINCT CASE WHEN status = 'won' THEN opportunity_id END)
    / NULLIF(
        COUNT(DISTINCT CASE WHEN status IN ('won','lost','abandoned') THEN opportunity_id END),
        0
      ),
    2
  ) AS conversion_rate_pct
FROM dim_opportunities
WHERE is_current = TRUE
  [[ AND location_id = {{location_id}} ]]
  [[ AND pipeline_id = {{pipeline_id}} ]]
  [[ AND ghl_created_at >= {{date_from}} ]]
  [[ AND ghl_created_at <= {{date_to}} ]]
