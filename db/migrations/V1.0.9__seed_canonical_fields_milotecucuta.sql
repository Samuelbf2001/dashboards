-- ─────────────────────────────────────────────────────────────────────────────
-- V1.0.9 — Catálogo canónico + mapeo milotecucuta
--
-- 1. Inserta 24 canonical_keys en ghl_custom_field_defs
--    (14 contact + 10 opportunity, sin los 16 stage_date que ya son columnas)
--
-- 2. Inserta los 24 mappings para milotecucuta (0IP2MEmSx0fpdVllDK5b)
--    con los GHL field_ids descubiertos vía /locations/{id}/customFields
--
-- Nota: proyecto_interes existe en contact Y opportunity — se nombran
--   proyecto_interes       (entity_type=contact)
--   opp_proyecto_interes   (entity_type=opportunity)
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Catálogo canónico ──────────────────────────────────────────────────────

INSERT INTO ghl_custom_field_defs
  (canonical_key, entity_type, data_type, label_es)
VALUES
  -- Contact (14)
  ('ciudad',                  'contact',     'text',    '¿De qué ciudad es?'),
  ('pais',                    'contact',     'text',    'País'),
  ('sexo',                    'contact',     'text',    'Sexo'),
  ('empresa',                 'contact',     'text',    'Empresa'),
  ('proyecto_interes',        'contact',     'text',    'Proyecto de interés'),
  ('etapa_actual_oportunidad','contact',     'text',    'Etapa actual de la oportunidad'),
  ('horizonte_compra',        'contact',     'text',    'Deseas tu compra para'),
  ('horizonte_construccion',  'contact',     'text',    '¿Cuándo quieres empezar a construir?'),
  ('ahorros_disponibles',     'contact',     'text',    '¿Cuentas con ahorros disponibles?'),
  ('capacidad_pago_mensual',  'contact',     'text',    '¿Cuál es tu capacidad de pago mensual?'),
  ('pago_mensual_max',        'contact',     'text',    '¿Cuánto podrías pagar mensualmente?'),
  ('situacion_actual',        'contact',     'text',    '¿Cuál opción describe mejor tu situación?'),
  ('tuvo_cita_programada',    'contact',     'text',    '¿Tuvo cita programada?'),
  ('ultima_interaccion',      'contact',     'date',    'Última interacción'),

  -- Opportunity (10)
  ('opp_proyecto_interes',    'opportunity', 'text',    'Proyecto de interés (oportunidad)'),
  ('opp_nuevo_proyecto',      'opportunity', 'text',    'Nuevo proyecto de interés'),
  ('tipo_propiedad',          'opportunity', 'text',    'Tipo de propiedad'),
  ('tipo_interes',            'opportunity', 'text',    '¿Cuál es el interés? (vivir/invertir)'),
  ('financia_con_nosotros',   'opportunity', 'text',    '¿Se financiará con nosotros?'),
  ('envio_forms_meta',        'opportunity', 'text',    '¿Envió forms de Meta?'),
  ('fuente_lead',             'opportunity', 'text',    'Fuente del Lead'),
  ('presupuesto',             'opportunity', 'number',  'Presupuesto'),
  ('cuota',                   'opportunity', 'number',  'Cuota'),
  ('tasa_interes',            'opportunity', 'number',  'Tasa de interés')

ON CONFLICT (canonical_key) DO NOTHING;

-- ── 2. Mapeo para milotecucuta (location_id = 0IP2MEmSx0fpdVllDK5b) ──────────

INSERT INTO ghl_custom_field_map
  (location_id, ghl_field_id, canonical_key, ghl_field_name)
VALUES
  -- Contact
  ('0IP2MEmSx0fpdVllDK5b', 'rfXynrmkaSVQ5s8tZzAK', 'ciudad',                   '¿De qué ciudad es?'),
  ('0IP2MEmSx0fpdVllDK5b', 'cz03TBUt4iNZPj6V9i8P', 'pais',                     'Pais'),
  ('0IP2MEmSx0fpdVllDK5b', 'ur1xEqVNR5vgvbS64LiO', 'sexo',                     'Sexo'),
  ('0IP2MEmSx0fpdVllDK5b', 'zwF95MQnV0TdAxsjWqEm', 'empresa',                  'Empresa'),
  ('0IP2MEmSx0fpdVllDK5b', '8FHl4wxZDr6oM1YbCuas', 'proyecto_interes',         'Proyecto de interes'),
  ('0IP2MEmSx0fpdVllDK5b', 'WVXAyDZm1Gkf3XJxBHi0', 'etapa_actual_oportunidad', 'Etapa actual de la oportunidad'),
  ('0IP2MEmSx0fpdVllDK5b', 'icfdqqP2M5YRp7gcFqew', 'horizonte_compra',         'Deseas tu compra para'),
  ('0IP2MEmSx0fpdVllDK5b', 'lgDPVIWqwd1GhsfCsmdh', 'horizonte_construccion',   '¿Cuándo quieres empezar a construir?'),
  ('0IP2MEmSx0fpdVllDK5b', 'RRlnAOmgZZFSawtKpULc', 'ahorros_disponibles',      '¿Cuentas con ahorros disponibles?'),
  ('0IP2MEmSx0fpdVllDK5b', 'RJUOiyI9Mmd6PrO3GVp2', 'capacidad_pago_mensual',   '¿Cuál es tu capacidad de pago mensual?'),
  ('0IP2MEmSx0fpdVllDK5b', '3lOWbpxthVqXrWCWUeFg', 'pago_mensual_max',         '¿Cuánto podrías pagar mensualmente?'),
  ('0IP2MEmSx0fpdVllDK5b', '5Cmj5RIbF0OERSzMMDRR', 'situacion_actual',         '¿Cuál de estas opciones describe mejor tu situación?'),
  ('0IP2MEmSx0fpdVllDK5b', 'esea3inqXknFTGgOvEbv', 'tuvo_cita_programada',     '¿tuvo cita programada?'),
  ('0IP2MEmSx0fpdVllDK5b', 'blfsVQNXB1dYwu61RZ26', 'ultima_interaccion',       'Ultimo interacción'),

  -- Opportunity
  ('0IP2MEmSx0fpdVllDK5b', '7eGMnihftgG0MQ7Ny1HT', 'opp_proyecto_interes',  'Proyecto de interés'),
  ('0IP2MEmSx0fpdVllDK5b', 'AKANZeQFFYqB9pqjRc71', 'opp_nuevo_proyecto',    'Nuevo proyecto de interés'),
  ('0IP2MEmSx0fpdVllDK5b', 'VzRrovbgDHIPYAkJ83yS', 'tipo_propiedad',        'Tipo de propiedad'),
  ('0IP2MEmSx0fpdVllDK5b', 'yQlUNjBiZtckRniNAEZv', 'tipo_interes',          '¿Cuál es el interés?'),
  ('0IP2MEmSx0fpdVllDK5b', 'jUMwaPMm0hCQztI6EHiw', 'financia_con_nosotros', '¿Se financiará con nosotros?'),
  ('0IP2MEmSx0fpdVllDK5b', 'AWxPOMSV2ROUtdaY6aLF', 'envio_forms_meta',      '¿Envió forms de meta?'),
  ('0IP2MEmSx0fpdVllDK5b', 'Do8JVPMmeZ0Y3K2xvnuD', 'fuente_lead',           'Fuente del Lead'),
  ('0IP2MEmSx0fpdVllDK5b', 'mx41rfi5Lr3eRJhfoko5', 'presupuesto',           'Presupuesto'),
  ('0IP2MEmSx0fpdVllDK5b', 'yNoJm1J2eEeZQDA5Nt39', 'cuota',                 'Cuota'),
  ('0IP2MEmSx0fpdVllDK5b', 'M1Xj7TX31NQ9avAkqD5c', 'tasa_interes',          'Tasa de interés')

ON CONFLICT DO NOTHING;

-- Verificación:
-- SELECT canonical_key, entity_type, data_type, label_es
-- FROM ghl_custom_field_defs ORDER BY entity_type, canonical_key;
--
-- SELECT m.canonical_key, m.ghl_field_name, d.entity_type, d.data_type
-- FROM ghl_custom_field_map m
-- JOIN ghl_custom_field_defs d USING (canonical_key)
-- WHERE m.location_id = '0IP2MEmSx0fpdVllDK5b'
-- ORDER BY d.entity_type, m.canonical_key;
