-- ─────────────────────────────────────────────────────────────────────────────
-- V1.0.13 — Onboarding Mizar (location HgN9ajLVkMEmPFeTrU9G)
--
-- 1. ghl_field_whitelist: 15 contact + 10 opportunity
-- 2. Rol client_loc_mizar + grants de lectura en tablas principales
-- 3. RLS policies por location en tablas de hechos
-- ─────────────────────────────────────────────────────────────────────────────


-- ── 1. Whitelist Mizar ────────────────────────────────────────────────────────
INSERT INTO ghl_field_whitelist (location_id, field_id, entity_type, label) VALUES

  -- Contact (15)
  ('HgN9ajLVkMEmPFeTrU9G', 'mzILE3wRvE9rgKQbaoKV', 'contact',     '¿De qué ciudad es?'),
  ('HgN9ajLVkMEmPFeTrU9G', '3FcceQK8yXFsBeWLvZJE', 'contact',     'País'),
  ('HgN9ajLVkMEmPFeTrU9G', 'tSB6ULlex8MmEx8YkFnR', 'contact',     'Sexo'),
  ('HgN9ajLVkMEmPFeTrU9G', 'OFt9yQ8SWatEDjufmSRb', 'contact',     'Empresa'),
  ('HgN9ajLVkMEmPFeTrU9G', 'GGm8PL4gwbu6ulLKr8TM', 'contact',     'Proyecto de interés'),
  ('HgN9ajLVkMEmPFeTrU9G', '4GFuZAiAcaLGeZunNoxy', 'contact',     'Etapa actual de la oportunidad'),
  ('HgN9ajLVkMEmPFeTrU9G', 'W5L3DXOAjj6xd1XTX1ef', 'contact',     '¿Para cuándo necesitas la entrega?'),
  ('HgN9ajLVkMEmPFeTrU9G', '2i4ib7RCCnJTfLJBLjrk', 'contact',     '¿Cuentas con ahorros disponibles?'),
  ('HgN9ajLVkMEmPFeTrU9G', 'mLDvF8VkpeDb2s4c12lS', 'contact',     '¿Cuál es tu capacidad de pago mensual?'),
  ('HgN9ajLVkMEmPFeTrU9G', 'jeSOyy0EFTJOwnHaFSKt', 'contact',     '¿Cuánto podrías pagar mensualmente?'),
  ('HgN9ajLVkMEmPFeTrU9G', 'XFcneXDK0xn4Xk2opDSA', 'contact',     '¿Tuvo cita programada?'),
  ('HgN9ajLVkMEmPFeTrU9G', 'Lu1m1HL36t3rXGHduVba', 'contact',     'Ultimo interacción'),
  ('HgN9ajLVkMEmPFeTrU9G', '5nJgVGxgWNKWj5rHyVSF', 'contact',     'Tipo de predio'),
  ('HgN9ajLVkMEmPFeTrU9G', '1WWksl9bBTFVW4MeboTt', 'contact',     '¿Cuánto tienes para la cuota inicial?'),
  ('HgN9ajLVkMEmPFeTrU9G', 'GfpG6Vxf7AiQoiSjWAeZ', 'contact',     '¿Cómo planeas pagar?'),

  -- Opportunity (10)
  ('HgN9ajLVkMEmPFeTrU9G', 'is6HSvPeYihQAywulanF', 'opportunity', 'Proyecto de interés'),
  ('HgN9ajLVkMEmPFeTrU9G', 'irnUUcvShQ6io7lPDDzv', 'opportunity', 'Nuevo proyecto de interés'),
  ('HgN9ajLVkMEmPFeTrU9G', 'KA7XQWjOIybV6IhLV5En', 'opportunity', 'Tipo de propiedad'),
  ('HgN9ajLVkMEmPFeTrU9G', 'NxIXcFZ4tIpA9TLw1Gf4', 'opportunity', '¿Cuál es el interés?'),
  ('HgN9ajLVkMEmPFeTrU9G', 'ISyrdIZMda7GsOKOyVgr', 'opportunity', '¿Se financiará con nosotros?'),
  ('HgN9ajLVkMEmPFeTrU9G', 'zEHRivl4dUIE2bihFUNK', 'opportunity', 'Fuente del Lead'),
  ('HgN9ajLVkMEmPFeTrU9G', 'qPma0HPu3aqj3VPxBsc7', 'opportunity', 'Presupuesto'),
  ('HgN9ajLVkMEmPFeTrU9G', 'wlEEdJd661hfcjhTQm7r', 'opportunity', 'Cuota'),
  ('HgN9ajLVkMEmPFeTrU9G', '8q8mpqMa1ytLkKZhnmlf', 'opportunity', 'Tasa de interés'),
  ('HgN9ajLVkMEmPFeTrU9G', 'vIurZJJTj46aZJaLlftS', 'opportunity', '¿Tiene cita agendada?')

ON CONFLICT DO NOTHING;


-- ── 2. Rol de acceso para Mizar ───────────────────────────────────────────────
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'client_loc_mizar') THEN
    CREATE ROLE client_loc_mizar NOLOGIN;
  END IF;
END $$;

GRANT SELECT ON
  dim_contacts,
  dim_opportunities,
  dim_conversations,
  ghl_appointments,
  fact_opp_stage_history,
  fact_messages,
  fact_contact_custom_fields,
  fact_opp_custom_fields,
  mv_unified_attribution,
  ghl_locations,
  ghl_field_whitelist
TO client_loc_mizar;


-- ── 3. RLS policies para Mizar ────────────────────────────────────────────────
CREATE POLICY rls_mizar_cf_contact
  ON fact_contact_custom_fields FOR ALL TO client_loc_mizar
  USING (location_id = 'HgN9ajLVkMEmPFeTrU9G');

CREATE POLICY rls_mizar_cf_opp
  ON fact_opp_custom_fields FOR ALL TO client_loc_mizar
  USING (location_id = 'HgN9ajLVkMEmPFeTrU9G');

CREATE POLICY rls_mizar_contacts
  ON dim_contacts FOR SELECT TO client_loc_mizar
  USING (location_id = 'HgN9ajLVkMEmPFeTrU9G');

CREATE POLICY rls_mizar_opportunities
  ON dim_opportunities FOR SELECT TO client_loc_mizar
  USING (location_id = 'HgN9ajLVkMEmPFeTrU9G');

CREATE POLICY rls_mizar_conversations
  ON dim_conversations FOR SELECT TO client_loc_mizar
  USING (location_id = 'HgN9ajLVkMEmPFeTrU9G');

CREATE POLICY rls_mizar_appointments
  ON ghl_appointments FOR SELECT TO client_loc_mizar
  USING (location_id = 'HgN9ajLVkMEmPFeTrU9G');

CREATE POLICY rls_mizar_stage_history
  ON fact_opp_stage_history FOR SELECT TO client_loc_mizar
  USING (location_id = 'HgN9ajLVkMEmPFeTrU9G');

CREATE POLICY rls_mizar_messages
  ON fact_messages FOR SELECT TO client_loc_mizar
  USING (location_id = 'HgN9ajLVkMEmPFeTrU9G');


-- ── 4. Verificación ───────────────────────────────────────────────────────────
\echo '── Whitelist Mizar'
SELECT entity_type, COUNT(*) AS campos
FROM ghl_field_whitelist
WHERE location_id = 'HgN9ajLVkMEmPFeTrU9G'
GROUP BY entity_type;

\echo '── ghl_locations'
SELECT location_id, client_name, client_slug, active FROM ghl_locations;
