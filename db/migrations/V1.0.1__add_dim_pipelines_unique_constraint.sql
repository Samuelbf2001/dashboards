-- ─── Migración V1.0.1 ─────────────────────────────────────────────────────
-- Fecha: 2026-05-20
-- Descripción: Añade constraint UNIQUE en dim_pipelines (pipeline_id, stage_id, location_id)
--   requerido por WF-13 para el upsert ON CONFLICT DO UPDATE.
--   Sin este constraint el workflow de polling de pipelines falla.
-- Rollback: ver sección ROLLBACK al final.
-- ─────────────────────────────────────────────────────────────────────────────

BEGIN;

ALTER TABLE dim_pipelines
  ADD CONSTRAINT uq_dim_pipelines_stage_location
  UNIQUE (pipeline_id, stage_id, location_id);

INSERT INTO migration_log (version, description, applied_by)
VALUES ('V1.0.1', 'Add UNIQUE constraint on dim_pipelines (pipeline_id, stage_id, location_id) for WF-13 upsert', 'system')
ON CONFLICT (version) DO NOTHING;

COMMIT;

-- ─── ROLLBACK ─────────────────────────────────────────────────────────────
-- ALTER TABLE dim_pipelines DROP CONSTRAINT IF EXISTS uq_dim_pipelines_stage_location;
