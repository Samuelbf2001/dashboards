-- ─────────────────────────────────────────────────────────────────────────────
-- V1.0.12 — Whitelist de custom fields aprobados por location
--
-- Problema: V1.0.11 escribía TODOS los campos del payload en fact_contact_custom_fields.
-- Solución: tabla ghl_field_whitelist que define qué field_ids se almacenan por location.
--           WF-01/02 harán JOIN contra esta tabla antes de insertar.
--
-- Pasos:
--  1. Crear ghl_field_whitelist
--  2. Seed milotecucuta (14 contact + 10 opportunity)
--  3. Truncar y re-backfill fact_contact_custom_fields filtrado
--  4. Truncar fact_opp_custom_fields (estaba vacía, queda limpia)
-- ─────────────────────────────────────────────────────────────────────────────


-- ── 1. Whitelist table ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ghl_field_whitelist (
  location_id  VARCHAR(50)   NOT NULL,
  field_id     VARCHAR(100)  NOT NULL,
  entity_type  VARCHAR(20)   NOT NULL CHECK (entity_type IN ('contact','opportunity')),
  label        VARCHAR(200),
  active       BOOLEAN       NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  PRIMARY KEY (location_id, field_id)
);

COMMENT ON TABLE ghl_field_whitelist IS
  'Campos custom aprobados para almacenarse en fact_*_custom_fields. '
  'PK: (location_id, field_id). Agregar filas aquí para habilitar un campo en un cliente.';

CREATE INDEX idx_whitelist_location ON ghl_field_whitelist(location_id, entity_type) WHERE active = TRUE;

GRANT SELECT ON ghl_field_whitelist TO n8n_writer;
GRANT ALL PRIVILEGES ON ghl_field_whitelist TO sixteam_admin;

ALTER TABLE ghl_field_whitelist ENABLE ROW LEVEL SECURITY;
ALTER TABLE ghl_field_whitelist FORCE  ROW LEVEL SECURITY;

CREATE POLICY rls_n8n_writer_whitelist
  ON ghl_field_whitelist FOR SELECT TO n8n_writer USING (TRUE);


-- ── 2. Seed milotecucuta (location 0IP2MEmSx0fpdVllDK5b) ─────────────────────
INSERT INTO ghl_field_whitelist (location_id, field_id, entity_type, label) VALUES

  -- Contact (14)
  ('0IP2MEmSx0fpdVllDK5b', 'rfXynrmkaSVQ5s8tZzAK', 'contact',     '¿De qué ciudad es?'),
  ('0IP2MEmSx0fpdVllDK5b', 'cz03TBUt4iNZPj6V9i8P', 'contact',     'Pais'),
  ('0IP2MEmSx0fpdVllDK5b', 'ur1xEqVNR5vgvbS64LiO', 'contact',     'Sexo'),
  ('0IP2MEmSx0fpdVllDK5b', 'zwF95MQnV0TdAxsjWqEm', 'contact',     'Empresa'),
  ('0IP2MEmSx0fpdVllDK5b', '8FHl4wxZDr6oM1YbCuas', 'contact',     'Proyecto de interes'),
  ('0IP2MEmSx0fpdVllDK5b', 'WVXAyDZm1Gkf3XJxBHi0', 'contact',     'Etapa actual de la oportunidad'),
  ('0IP2MEmSx0fpdVllDK5b', 'icfdqqP2M5YRp7gcFqew', 'contact',     'Deseas tu compra para'),
  ('0IP2MEmSx0fpdVllDK5b', 'lgDPVIWqwd1GhsfCsmdh', 'contact',     '¿Cuándo quieres empezar a construir?'),
  ('0IP2MEmSx0fpdVllDK5b', 'RRlnAOmgZZFSawtKpULc', 'contact',     '¿Cuentas con ahorros disponibles?'),
  ('0IP2MEmSx0fpdVllDK5b', 'RJUOiyI9Mmd6PrO3GVp2', 'contact',     '¿Cuál es tu capacidad de pago mensual?'),
  ('0IP2MEmSx0fpdVllDK5b', '3lOWbpxthVqXrWCWUeFg', 'contact',     '¿Cuánto podrías pagar mensualmente?'),
  ('0IP2MEmSx0fpdVllDK5b', '5Cmj5RIbF0OERSzMMDRR', 'contact',     '¿Cuál de estas opciones describe mejor tu situación?'),
  ('0IP2MEmSx0fpdVllDK5b', 'esea3inqXknFTGgOvEbv', 'contact',     '¿tuvo cita programada?'),
  ('0IP2MEmSx0fpdVllDK5b', 'blfsVQNXB1dYwu61RZ26', 'contact',     'Ultimo interacción'),

  -- Opportunity (10)
  ('0IP2MEmSx0fpdVllDK5b', '7eGMnihftgG0MQ7Ny1HT', 'opportunity', 'Proyecto de interés'),
  ('0IP2MEmSx0fpdVllDK5b', 'AKANZeQFFYqB9pqjRc71', 'opportunity', 'Nuevo proyecto de interés'),
  ('0IP2MEmSx0fpdVllDK5b', 'VzRrovbgDHIPYAkJ83yS', 'opportunity', 'Tipo de propiedad'),
  ('0IP2MEmSx0fpdVllDK5b', 'yQlUNjBiZtckRniNAEZv', 'opportunity', '¿Cuál es el interés?'),
  ('0IP2MEmSx0fpdVllDK5b', 'jUMwaPMm0hCQztI6EHiw', 'opportunity', '¿Se financiará con nosotros?'),
  ('0IP2MEmSx0fpdVllDK5b', 'AWxPOMSV2ROUtdaY6aLF', 'opportunity', '¿Envió forms de meta?'),
  ('0IP2MEmSx0fpdVllDK5b', 'Do8JVPMmeZ0Y3K2xvnuD', 'opportunity', 'Fuente del Lead'),
  ('0IP2MEmSx0fpdVllDK5b', 'mx41rfi5Lr3eRJhfoko5', 'opportunity', 'Presupuesto'),
  ('0IP2MEmSx0fpdVllDK5b', 'yNoJm1J2eEeZQDA5Nt39', 'opportunity', 'Cuota'),
  ('0IP2MEmSx0fpdVllDK5b', 'M1Xj7TX31NQ9avAkqD5c', 'opportunity', 'Tasa de interés')

ON CONFLICT DO NOTHING;


-- ── 3. Limpiar y re-backfill fact_contact_custom_fields (solo whitelisted) ────
TRUNCATE fact_contact_custom_fields;

INSERT INTO fact_contact_custom_fields
  (contact_id, location_id, field_id, value_text, value_number, value_date, updated_at)
SELECT
  c.contact_id,
  c.location_id,
  cf->>'id'                                                    AS field_id,
  CASE
    WHEN (cf->>'value') ~ '^\d{4}-\d{2}-\d{2}'               THEN NULL
    WHEN (cf->>'value') ~ '^-?\d+(\.\d+)?$'                   THEN NULL
    ELSE cf->>'value'
  END                                                          AS value_text,
  CASE
    WHEN (cf->>'value') ~ '^-?\d+(\.\d+)?$'
    THEN (cf->>'value')::NUMERIC
  END                                                          AS value_number,
  CASE
    WHEN (cf->>'value') ~ '^\d{4}-\d{2}-\d{2}'
    THEN (substring(cf->>'value', 1, 10))::DATE
  END                                                          AS value_date,
  NOW()
FROM dim_contacts c
CROSS JOIN LATERAL jsonb_array_elements(
  CASE
    WHEN c.custom_fields IS NULL                  THEN '[]'::jsonb
    WHEN jsonb_typeof(c.custom_fields) = 'array'  THEN c.custom_fields
    ELSE '[]'::jsonb
  END
) AS cf
JOIN ghl_field_whitelist w
  ON  w.location_id = c.location_id
  AND w.field_id    = cf->>'id'
  AND w.entity_type = 'contact'
  AND w.active      = TRUE
WHERE c.is_current = TRUE
  AND cf->>'value' IS NOT NULL
  AND cf->>'value' <> ''
ON CONFLICT (contact_id, field_id) DO UPDATE SET
  value_text   = EXCLUDED.value_text,
  value_number = EXCLUDED.value_number,
  value_date   = EXCLUDED.value_date,
  updated_at   = NOW();


-- ── 4. Limpiar fact_opp_custom_fields (histórico vacío, queda limpio) ─────────
TRUNCATE fact_opp_custom_fields;
-- dim_opportunities.custom_fields es NULL en todos los registros históricos.
-- Los datos se llenarán hacia adelante via WF-02 con el JOIN correcto.


-- ── 5. Resumen ────────────────────────────────────────────────────────────────
\echo '── Whitelist por entity_type'
SELECT entity_type, COUNT(*) AS campos FROM ghl_field_whitelist GROUP BY entity_type;

\echo '── fact_contact_custom_fields (top 20 field_ids después del backfill filtrado)'
SELECT
  w.label,
  f.field_id,
  COUNT(*) AS registros
FROM fact_contact_custom_fields f
JOIN ghl_field_whitelist w USING (location_id, field_id)
GROUP BY w.label, f.field_id
ORDER BY registros DESC
LIMIT 20;

\echo '── Total filas fact_contact_custom_fields'
SELECT COUNT(*) FROM fact_contact_custom_fields;
