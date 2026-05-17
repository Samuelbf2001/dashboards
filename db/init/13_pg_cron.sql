-- ─────────────────────────────────────────────────────────────────────────────
-- 13_pg_cron.sql — Programación de jobs con pg_cron
-- Requiere: shared_preload_libraries=pg_cron en postgresql.conf
--           y cron.database_name=ghl_analytics en postgresql.conf
-- Los jobs se almacenan en la tabla cron.job del schema cron.
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── Refresh de la vista materializada — cada hora en punto ──────────────────
-- REFRESH CONCURRENTLY no bloquea lecturas; requiere el índice UNIQUE creado
-- en 12_mv_unified_attribution.sql (idx_mv_unique_row).
-- Cron expression: '0 * * * *' = minuto 0 de cada hora, todos los días.
SELECT cron.schedule(
  'refresh_mv_unified_attribution',          -- nombre único del job
  '0 * * * *',                               -- cada hora en punto
  'REFRESH MATERIALIZED VIEW CONCURRENTLY mv_unified_attribution'
);

-- ─── Verificación de jobs programados ────────────────────────────────────────
-- Consultar el estado de los jobs:
--   SELECT jobid, jobname, schedule, command, active
--   FROM cron.job;
--
-- Consultar el historial de ejecuciones:
--   SELECT jobid, job_pid, run_time, status, return_message
--   FROM cron.job_run_details
--   ORDER BY run_time DESC LIMIT 10;
--
-- Desactivar un job sin eliminarlo:
--   SELECT cron.unschedule('refresh_mv_unified_attribution');
--
-- Reactivar:
--   SELECT cron.schedule(
--     'refresh_mv_unified_attribution',
--     '0 * * * *',
--     'REFRESH MATERIALIZED VIEW CONCURRENTLY mv_unified_attribution'
--   );
