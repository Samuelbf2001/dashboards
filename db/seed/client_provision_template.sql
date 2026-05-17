-- ─────────────────────────────────────────────────────────────────────────────
-- client_provision_template.sql — Provisionamiento de cliente en GHL Analytics
-- Script parametrizado por LOCATION_ID y CLIENT_SLUG.
-- Se ejecuta UNA VEZ por cliente al momento del onboarding.
--
-- VARIABLES:
--   ${LOCATION_ID}   → ID del subaccount en GHL (ej: loc_abc123def456)
--   ${CLIENT_SLUG}   → Slug alfanumérico del cliente (ej: acme, empresa_x)
--   ${CLIENT_PASSWORD} → Contraseña del rol (usar EasyPanel Secret Manager)
--
-- MÉTODOS DE USO:
--
-- Opción A — sed (reemplaza variables en bash antes de ejecutar):
--   sed -e 's/${LOCATION_ID}/loc_abc123def456/g' \
--       -e 's/${CLIENT_SLUG}/acme/g' \
--       -e 's/${CLIENT_PASSWORD}/[SECRETO]/g' \
--       client_provision_template.sql | \
--   psql -h localhost -U sixteam_admin -d ghl_analytics
--
-- Opción B — psql variables (-v):
--   psql -h localhost -U sixteam_admin -d ghl_analytics \
--     -v LOCATION_ID='loc_abc123def456' \
--     -v CLIENT_SLUG='acme' \
--     -v CLIENT_PASSWORD='[SECRETO]' \
--     -f client_provision_template.sql
--   (En el script usar :'LOCATION_ID' en lugar de '${LOCATION_ID}')
--
-- Opción C — n8n Code node (reemplazar en runtime con string.replace())
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── 1. Crear rol de cliente ──────────────────────────────────────────────────
-- El nombre del rol sigue el contrato: client_loc_<slug>
-- La contraseña NUNCA debe hardcodearse — usar Secret Manager
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = 'client_loc_${CLIENT_SLUG}'
  ) THEN
    CREATE ROLE client_loc_${CLIENT_SLUG} LOGIN PASSWORD '${CLIENT_PASSWORD}';
  ELSE
    RAISE NOTICE 'El rol client_loc_${CLIENT_SLUG} ya existe — se omite CREATE ROLE';
  END IF;
END
$$;

-- ─── 2. Otorgar SELECT en todas las tablas de analytics ──────────────────────
GRANT SELECT ON ALL TABLES IN SCHEMA public TO client_loc_${CLIENT_SLUG};
GRANT USAGE ON SCHEMA public TO client_loc_${CLIENT_SLUG};

-- ─── 3. Otorgar SELECT en la vista materializada ─────────────────────────────
-- La MV se genera en 12_mv_unified_attribution.sql
GRANT SELECT ON mv_unified_attribution TO client_loc_${CLIENT_SLUG};

-- ─── 4. Crear políticas RLS por tabla ────────────────────────────────────────
-- Cada policy filtra SOLO las filas del location_id de este cliente.
-- FOR ALL = aplica a SELECT, INSERT, UPDATE, DELETE (solo SELECT tiene efecto
-- dado que el rol solo tiene GRANT SELECT).

CREATE POLICY rls_contacts_${CLIENT_SLUG}
  ON dim_contacts
  FOR ALL TO client_loc_${CLIENT_SLUG}
  USING (location_id = '${LOCATION_ID}');

CREATE POLICY rls_opps_${CLIENT_SLUG}
  ON dim_opportunities
  FOR ALL TO client_loc_${CLIENT_SLUG}
  USING (location_id = '${LOCATION_ID}');

CREATE POLICY rls_conv_${CLIENT_SLUG}
  ON dim_conversations
  FOR ALL TO client_loc_${CLIENT_SLUG}
  USING (location_id = '${LOCATION_ID}');

CREATE POLICY rls_pipelines_${CLIENT_SLUG}
  ON dim_pipelines
  FOR ALL TO client_loc_${CLIENT_SLUG}
  USING (location_id = '${LOCATION_ID}');

CREATE POLICY rls_ads_${CLIENT_SLUG}
  ON dim_ads
  FOR ALL TO client_loc_${CLIENT_SLUG}
  USING (location_id = '${LOCATION_ID}');

CREATE POLICY rls_messages_${CLIENT_SLUG}
  ON fact_messages
  FOR ALL TO client_loc_${CLIENT_SLUG}
  USING (location_id = '${LOCATION_ID}');

CREATE POLICY rls_opp_hist_${CLIENT_SLUG}
  ON fact_opp_stage_history
  FOR ALL TO client_loc_${CLIENT_SLUG}
  USING (location_id = '${LOCATION_ID}');

CREATE POLICY rls_email_evt_${CLIENT_SLUG}
  ON fact_email_events
  FOR ALL TO client_loc_${CLIENT_SLUG}
  USING (location_id = '${LOCATION_ID}');

CREATE POLICY rls_ctwa_${CLIENT_SLUG}
  ON fact_ctwa_clicks
  FOR ALL TO client_loc_${CLIENT_SLUG}
  USING (location_id = '${LOCATION_ID}');

CREATE POLICY rls_appt_${CLIENT_SLUG}
  ON ghl_appointments
  FOR ALL TO client_loc_${CLIENT_SLUG}
  USING (location_id = '${LOCATION_ID}');

-- ─── 5. Inicializar el cursor de polling para el nuevo cliente ────────────────
-- Insertar filas en ghl_sync_state para todas las entidades.
-- last_synced_at = NULL indica que no se ha hecho ningún polling aún
-- (el workflow de polling tratará esto como backfill completo).
INSERT INTO ghl_sync_state (entity, location_id, last_synced_at, records_synced, updated_at)
VALUES
  ('contacts',      '${LOCATION_ID}', NULL, 0, NOW()),
  ('opportunities', '${LOCATION_ID}', NULL, 0, NOW()),
  ('appointments',  '${LOCATION_ID}', NULL, 0, NOW()),
  ('pipelines',     '${LOCATION_ID}', NULL, 0, NOW()),
  ('ads',           '${LOCATION_ID}', NULL, 0, NOW())
ON CONFLICT (entity, location_id) DO NOTHING;

-- ─── 6. Verificación ─────────────────────────────────────────────────────────
-- Confirmar que el rol y las policies existen:
--
-- SELECT rolname FROM pg_roles WHERE rolname = 'client_loc_${CLIENT_SLUG}';
--
-- SELECT tablename, policyname, roles
-- FROM pg_policies
-- WHERE roles @> ARRAY['client_loc_${CLIENT_SLUG}'];
--
-- Probar aislamiento RLS (debe retornar 0 si no hay datos del cliente aún):
--
-- SET ROLE client_loc_${CLIENT_SLUG};
-- SELECT COUNT(*) FROM dim_contacts;   -- retorna solo filas de ${LOCATION_ID}
-- RESET ROLE;
