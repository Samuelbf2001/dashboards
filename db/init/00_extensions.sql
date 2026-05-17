-- ─────────────────────────────────────────────────────────────────────────────
-- 00_extensions.sql — Extensiones de PostgreSQL requeridas
-- Orden de ejecución: PRIMERO (antes de cualquier CREATE TABLE)
-- Requiere: imagen con pgvector disponible (pgvector/pgvector:pg16)
--           y shared_preload_libraries=pg_cron en el comando de postgres
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── pgvector ── Búsqueda semántica con embeddings vector(1536) ──────────────
CREATE EXTENSION IF NOT EXISTS pgvector;

-- ─── pg_cron ── Scheduler de jobs SQL dentro de PostgreSQL ───────────────────
-- IMPORTANTE: requiere shared_preload_libraries=pg_cron en postgresql.conf
-- y cron.database_name=<nombre_bd> para que cron.schedule() funcione
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ─── uuid-ossp ── Generación de UUIDs (disponible en el schema public) ────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
