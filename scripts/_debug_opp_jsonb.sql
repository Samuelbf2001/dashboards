\echo '── Conteos por tipo JSONB'
SELECT
  jsonb_typeof(custom_fields)  AS tipo_jsonb,
  COUNT(*)                     AS total
FROM dim_opportunities
WHERE is_current = TRUE AND location_id = '0IP2MEmSx0fpdVllDK5b'
GROUP BY jsonb_typeof(custom_fields);

\echo '── Primeras 2 filas con custom_fields no vacío'
SELECT opportunity_id, custom_fields
FROM dim_opportunities
WHERE is_current = TRUE
  AND location_id = '0IP2MEmSx0fpdVllDK5b'
  AND custom_fields IS NOT NULL
  AND custom_fields::text != 'null'
LIMIT 2;
