-- ─────────────────────────────────────────────────────────────────────────────
-- 09_sync_state.sql — Cursor de sincronización incremental
-- Una fila por entidad × location_id. Permite que el polling de n8n
-- retome exactamente donde lo dejó si n8n se reinicia o el VPS tiene una caída.
-- NUNCA eliminar filas de esta tabla.
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── ghl_sync_state ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ghl_sync_state (
  -- PK compuesta: entidad + subaccount de GHL
  entity         VARCHAR(50)      NOT NULL, -- contacts | opportunities | appointments | pipelines | ads
  location_id    VARCHAR(50)      NOT NULL, -- Subaccount GHL

  -- ─── Cursor de polling ───────────────────────────────────────────────────
  -- Timestamp del último registro procesado exitosamente
  -- El workflow de polling consulta: WHERE ghl_updated_at > last_synced_at
  last_synced_at TIMESTAMPTZ,

  -- Token de paginación de GHL API para retomar si el polling fue interrumpido
  last_cursor    VARCHAR(500),

  -- ─── Estadísticas ────────────────────────────────────────────────────────
  records_synced BIGINT           DEFAULT 0, -- Total registros sincronizados (acumulado histórico)
  last_error     TEXT,                       -- Último error capturado; NULL si la última ejecución fue exitosa

  updated_at     TIMESTAMPTZ      NOT NULL DEFAULT NOW(),

  PRIMARY KEY (entity, location_id)
);

COMMENT ON TABLE ghl_sync_state IS
  'Cursor de sincronización incremental para workflows de polling de n8n. '
  'Una fila por (entity, location_id). '
  'NUNCA eliminar filas — permite backfill y reanudación tras reinicios.';
