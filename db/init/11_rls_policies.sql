-- ─────────────────────────────────────────────────────────────────────────────
-- 11_rls_policies.sql — Row Level Security
-- Habilitar RLS en las 9 tablas de analytics.
-- Política permisiva para n8n_writer (escritura sin restricción).
-- Políticas de cliente se crean con client_provision_template.sql.
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── 1. Habilitar RLS en todas las tablas ────────────────────────────────────
ALTER TABLE dim_contacts             ENABLE ROW LEVEL SECURITY;
ALTER TABLE dim_opportunities        ENABLE ROW LEVEL SECURITY;
ALTER TABLE dim_conversations        ENABLE ROW LEVEL SECURITY;
ALTER TABLE dim_pipelines            ENABLE ROW LEVEL SECURITY;
ALTER TABLE dim_ads                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE fact_messages            ENABLE ROW LEVEL SECURITY;
ALTER TABLE fact_opp_stage_history   ENABLE ROW LEVEL SECURITY;
ALTER TABLE fact_email_events        ENABLE ROW LEVEL SECURITY;
ALTER TABLE fact_ctwa_clicks         ENABLE ROW LEVEL SECURITY;

-- ─── 2. FORCE ROW LEVEL SECURITY ─────────────────────────────────────────────
-- Aplica RLS incluso al dueño de la tabla (excepto superusuarios de PostgreSQL)
-- sixteam_admin tiene BYPASSRLS — no se ve afectado por FORCE.
ALTER TABLE dim_contacts             FORCE ROW LEVEL SECURITY;
ALTER TABLE dim_opportunities        FORCE ROW LEVEL SECURITY;
ALTER TABLE dim_conversations        FORCE ROW LEVEL SECURITY;
ALTER TABLE dim_pipelines            FORCE ROW LEVEL SECURITY;
ALTER TABLE dim_ads                  FORCE ROW LEVEL SECURITY;
ALTER TABLE fact_messages            FORCE ROW LEVEL SECURITY;
ALTER TABLE fact_opp_stage_history   FORCE ROW LEVEL SECURITY;
ALTER TABLE fact_email_events        FORCE ROW LEVEL SECURITY;
ALTER TABLE fact_ctwa_clicks         FORCE ROW LEVEL SECURITY;

-- ─── 3. Política permisiva para n8n_writer ───────────────────────────────────
-- n8n_writer es el único rol que inserta/actualiza datos.
-- Necesita acceso irrestricto — USING(TRUE) permite ver/modificar cualquier fila.
-- IMPORTANTE: nunca exponer este rol a usuarios finales.

CREATE POLICY rls_n8n_writer_contacts
  ON dim_contacts
  FOR ALL TO n8n_writer
  USING (TRUE) WITH CHECK (TRUE);

CREATE POLICY rls_n8n_writer_opportunities
  ON dim_opportunities
  FOR ALL TO n8n_writer
  USING (TRUE) WITH CHECK (TRUE);

CREATE POLICY rls_n8n_writer_conversations
  ON dim_conversations
  FOR ALL TO n8n_writer
  USING (TRUE) WITH CHECK (TRUE);

CREATE POLICY rls_n8n_writer_pipelines
  ON dim_pipelines
  FOR ALL TO n8n_writer
  USING (TRUE) WITH CHECK (TRUE);

CREATE POLICY rls_n8n_writer_ads
  ON dim_ads
  FOR ALL TO n8n_writer
  USING (TRUE) WITH CHECK (TRUE);

CREATE POLICY rls_n8n_writer_messages
  ON fact_messages
  FOR ALL TO n8n_writer
  USING (TRUE) WITH CHECK (TRUE);

CREATE POLICY rls_n8n_writer_opp_hist
  ON fact_opp_stage_history
  FOR ALL TO n8n_writer
  USING (TRUE) WITH CHECK (TRUE);

CREATE POLICY rls_n8n_writer_email_evt
  ON fact_email_events
  FOR ALL TO n8n_writer
  USING (TRUE) WITH CHECK (TRUE);

CREATE POLICY rls_n8n_writer_ctwa
  ON fact_ctwa_clicks
  FOR ALL TO n8n_writer
  USING (TRUE) WITH CHECK (TRUE);

-- ─── 4. Grants de tabla para los roles ya creados ────────────────────────────
-- Asegurar que los privilegios DEFAULT se hayan materializado en las tablas existentes

GRANT INSERT, UPDATE, DELETE, SELECT ON ALL TABLES IN SCHEMA public TO n8n_writer;
GRANT USAGE, UPDATE ON ALL SEQUENCES IN SCHEMA public TO n8n_writer;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO sixteam_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO sixteam_admin;

-- ─── 5. Template de policy por cliente ───────────────────────────────────────
-- Ejecutar el script db/seed/client_provision_template.sql para cada cliente.
-- Patrón repetible — reemplazar <SLUG> y <LOCATION_ID>:
--
-- CREATE POLICY rls_contacts_<SLUG> ON dim_contacts
--   FOR ALL TO client_loc_<SLUG>
--   USING (location_id = '<LOCATION_ID>');
--
-- CREATE POLICY rls_opps_<SLUG> ON dim_opportunities
--   FOR ALL TO client_loc_<SLUG>
--   USING (location_id = '<LOCATION_ID>');
--
-- CREATE POLICY rls_conv_<SLUG> ON dim_conversations
--   FOR ALL TO client_loc_<SLUG>
--   USING (location_id = '<LOCATION_ID>');
--
-- CREATE POLICY rls_pipelines_<SLUG> ON dim_pipelines
--   FOR ALL TO client_loc_<SLUG>
--   USING (location_id = '<LOCATION_ID>');
--
-- CREATE POLICY rls_ads_<SLUG> ON dim_ads
--   FOR ALL TO client_loc_<SLUG>
--   USING (location_id = '<LOCATION_ID>');
--
-- CREATE POLICY rls_messages_<SLUG> ON fact_messages
--   FOR ALL TO client_loc_<SLUG>
--   USING (location_id = '<LOCATION_ID>');
--
-- CREATE POLICY rls_opp_hist_<SLUG> ON fact_opp_stage_history
--   FOR ALL TO client_loc_<SLUG>
--   USING (location_id = '<LOCATION_ID>');
--
-- CREATE POLICY rls_email_evt_<SLUG> ON fact_email_events
--   FOR ALL TO client_loc_<SLUG>
--   USING (location_id = '<LOCATION_ID>');
--
-- CREATE POLICY rls_ctwa_<SLUG> ON fact_ctwa_clicks
--   FOR ALL TO client_loc_<SLUG>
--   USING (location_id = '<LOCATION_ID>');
