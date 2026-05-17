-- ─────────────────────────────────────────────────────────────────────────────
-- 01_roles.sql — Roles de PostgreSQL
-- Contratos de nombres (inmutables — consumidos por Agentes 2 y 3):
--   sixteam_admin  → BYPASSRLS, todos los privilegios, Metabase Admin
--   n8n_writer     → INSERT/UPDATE/DELETE/SELECT, policy permisiva RLS
--   client_loc_<slug> → SELECT únicamente, RLS filtra por location_id
--
-- NOTA: Las contraseñas se asignan desde EasyPanel Secret Manager.
--       Este script crea los roles SIN contraseña; el operador debe
--       ejecutar ALTER ROLE ... PASSWORD '...' una vez desplegado.
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── sixteam_admin ── Superadmin de Sixteam ──────────────────────────────────
-- BYPASSRLS: ve todos los datos independientemente de las políticas RLS.
-- Usado por Metabase para dashboards internos de agencia.
-- NUNCA exponer este rol a usuarios externos.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sixteam_admin') THEN
    CREATE ROLE sixteam_admin BYPASSRLS LOGIN;
  END IF;
END
$$;

-- ─── n8n_writer ── Rol de escritura para el ETL de n8n ───────────────────────
-- Puede INSERT, UPDATE, DELETE y SELECT en todas las tablas.
-- La política RLS permisiva (11_rls_policies.sql) permite escritura sin filtro.
-- NO es BYPASSRLS — opera bajo RLS con policy USING(TRUE).
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'n8n_writer') THEN
    CREATE ROLE n8n_writer LOGIN;
  END IF;
END
$$;

-- ─── Privilegios sobre el schema public ──────────────────────────────────────
-- Se otorgan AFTER que las tablas existen (ver scripts 02..09).
-- Aquí se preparan los privilegios DEFAULT para tablas futuras.

-- sixteam_admin: todos los privilegios en tablas existentes y futuras
GRANT ALL PRIVILEGES ON SCHEMA public TO sixteam_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL ON TABLES TO sixteam_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL ON SEQUENCES TO sixteam_admin;

-- n8n_writer: escritura completa en tablas existentes y futuras
GRANT USAGE ON SCHEMA public TO n8n_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT INSERT, UPDATE, DELETE, SELECT ON TABLES TO n8n_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, UPDATE ON SEQUENCES TO n8n_writer;

-- ─── Bases de datos internas (n8n y Metabase) ────────────────────────────────
-- n8n necesita su propia BD aislada para estado interno
-- Metabase necesita su propia BD aislada para su estado de aplicación
-- Se crean aquí para que estén disponibles cuando los contenedores arranquen.

CREATE DATABASE n8n_internal;
CREATE DATABASE metabase_app;

-- Usuario dedicado para n8n (accede a n8n_internal + ghl_analytics)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'n8n_user') THEN
    CREATE ROLE n8n_user LOGIN;
  END IF;
END
$$;

GRANT ALL PRIVILEGES ON DATABASE n8n_internal TO n8n_user;
-- n8n_user debe poder conectar a ghl_analytics usando el rol n8n_writer
GRANT n8n_writer TO n8n_user;

-- Usuario dedicado para Metabase (accede a metabase_app + ghl_analytics)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'metabase_user') THEN
    CREATE ROLE metabase_user LOGIN;
  END IF;
END
$$;

GRANT ALL PRIVILEGES ON DATABASE metabase_app TO metabase_user;
-- metabase_user necesita SELECT en ghl_analytics para sixteam_admin conn
GRANT sixteam_admin TO metabase_user;

-- ─── Template para roles de cliente ──────────────────────────────────────────
-- Ejecutar el script db/seed/client_provision_template.sql por cada cliente.
-- Cada cliente recibe:
--   CREATE ROLE client_loc_<slug> LOGIN PASSWORD '<secreto>';
--   GRANT SELECT ON ALL TABLES IN SCHEMA public TO client_loc_<slug>;
--   CREATE POLICY ... USING (location_id = '<location_id>') en las 9 tablas
--
-- Ejemplo (NO ejecutar aquí — es ilustrativo):
-- CREATE ROLE client_loc_acme LOGIN PASSWORD '[SECRETO]';
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO client_loc_acme;
