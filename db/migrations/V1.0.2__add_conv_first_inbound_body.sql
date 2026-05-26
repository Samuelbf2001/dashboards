-- ─────────────────────────────────────────────────────────────────────────────
-- V1.0.2 — Añade first_inbound_body a dim_conversations
--          y el índice UNIQUE parcial requerido para upserts correctos
-- Ejecutar en entornos ya desplegados (el init SQL ya incluye estos cambios).
-- ─────────────────────────────────────────────────────────────────────────────

-- Columna para guardar el texto del primer mensaje del cliente
ALTER TABLE dim_conversations
  ADD COLUMN IF NOT EXISTS first_inbound_body TEXT;

-- Índice UNIQUE parcial: un solo registro activo por conversation_id
-- WF-03 y WF-14 usan ON CONFLICT (conversation_id) WHERE is_current
CREATE UNIQUE INDEX IF NOT EXISTS uniq_conv_current
  ON dim_conversations(conversation_id)
  WHERE is_current = TRUE;
