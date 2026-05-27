-- ─────────────────────────────────────────────────────────────────────────────
-- V1.0.10 — Backfill fact_contact_custom_fields y fact_opp_custom_fields
--
-- Lee el JSONB histórico de dim_contacts y dim_opportunities,
-- aplica el mapeo de ghl_custom_field_map, y popula las fact tables.
--
-- Seguro para re-ejecutar: usa ON CONFLICT DO UPDATE.
-- Solo procesa la versión actual (is_current=TRUE) de cada entidad.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Backfill CONTACTOS ─────────────────────────────────────────────────────
INSERT INTO fact_contact_custom_fields
  (contact_id, location_id, canonical_key, value_text, value_number, value_date, updated_at)
SELECT
  c.contact_id,
  c.location_id,
  m.canonical_key,
  CASE WHEN d.data_type IN ('text','select') THEN cf_item->>'value' END          AS value_text,
  CASE WHEN d.data_type = 'number'
       THEN (cf_item->>'value')::NUMERIC                                          END AS value_number,
  CASE WHEN d.data_type = 'date'
       THEN (cf_item->>'value')::DATE                                             END AS value_date,
  NOW()                                                                          AS updated_at
FROM dim_contacts c
-- Expandir el JSONB array de custom_fields
CROSS JOIN LATERAL jsonb_array_elements(
  CASE
    WHEN c.custom_fields IS NULL OR c.custom_fields = 'null' THEN '[]'::jsonb
    WHEN jsonb_typeof(c.custom_fields) = 'array'             THEN c.custom_fields
    ELSE '[]'::jsonb
  END
) AS cf_item
-- Resolver el field_id al canonical_key
JOIN ghl_custom_field_map m
  ON  m.location_id  = c.location_id
  AND m.ghl_field_id = cf_item->>'id'
  AND m.active       = TRUE
JOIN ghl_custom_field_defs d
  ON  d.canonical_key  = m.canonical_key
  AND d.entity_type    = 'contact'
-- Solo la versión actual del contacto
WHERE c.is_current = TRUE
  AND cf_item->>'value' IS NOT NULL
  AND cf_item->>'value' <> ''
ON CONFLICT (contact_id, canonical_key) DO UPDATE SET
  value_text   = EXCLUDED.value_text,
  value_number = EXCLUDED.value_number,
  value_date   = EXCLUDED.value_date,
  updated_at   = NOW();

-- ── 2. Backfill OPORTUNIDADES ─────────────────────────────────────────────────
INSERT INTO fact_opp_custom_fields
  (opportunity_id, location_id, canonical_key, value_text, value_number, value_date, updated_at)
SELECT
  o.opportunity_id,
  o.location_id,
  m.canonical_key,
  CASE WHEN d.data_type IN ('text','select') THEN cf_item->>'value' END          AS value_text,
  CASE WHEN d.data_type = 'number'
       THEN (cf_item->>'value')::NUMERIC                                          END AS value_number,
  CASE WHEN d.data_type = 'date'
       THEN (cf_item->>'value')::DATE                                             END AS value_date,
  NOW()                                                                          AS updated_at
FROM dim_opportunities o
CROSS JOIN LATERAL jsonb_array_elements(
  CASE
    WHEN o.custom_fields IS NULL OR o.custom_fields = 'null' THEN '[]'::jsonb
    WHEN jsonb_typeof(o.custom_fields) = 'array'             THEN o.custom_fields
    ELSE '[]'::jsonb
  END
) AS cf_item
JOIN ghl_custom_field_map m
  ON  m.location_id  = o.location_id
  AND m.ghl_field_id = cf_item->>'id'
  AND m.active       = TRUE
JOIN ghl_custom_field_defs d
  ON  d.canonical_key  = m.canonical_key
  AND d.entity_type    = 'opportunity'
WHERE o.is_current = TRUE
  AND cf_item->>'value' IS NOT NULL
  AND cf_item->>'value' <> ''
ON CONFLICT (opportunity_id, canonical_key) DO UPDATE SET
  value_text   = EXCLUDED.value_text,
  value_number = EXCLUDED.value_number,
  value_date   = EXCLUDED.value_date,
  updated_at   = NOW();

-- ── 3. Conteos finales ────────────────────────────────────────────────────────
\echo '── Backfill contactos por canonical_key'
SELECT canonical_key, COUNT(*) AS filas, COUNT(value_text) AS con_texto,
       COUNT(value_number) AS con_numero, COUNT(value_date) AS con_fecha
FROM fact_contact_custom_fields
GROUP BY canonical_key ORDER BY filas DESC;

\echo '── Backfill oportunidades por canonical_key'
SELECT canonical_key, COUNT(*) AS filas, COUNT(value_text) AS con_texto,
       COUNT(value_number) AS con_numero
FROM fact_opp_custom_fields
GROUP BY canonical_key ORDER BY filas DESC;
