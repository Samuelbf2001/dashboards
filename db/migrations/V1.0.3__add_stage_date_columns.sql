-- V1.0.3 — Añade columnas DATE de tracking de etapas a dim_opportunities
-- Corresponde a los 16 custom fields creados en GHL (carpeta Interno)
-- actualizados en tiempo real por WF-14 vía webhook OpportunityStageUpdate.

ALTER TABLE dim_opportunities
  ADD COLUMN IF NOT EXISTS stage_nuevo_lead_entrada       DATE,
  ADD COLUMN IF NOT EXISTS stage_nuevo_lead_salida        DATE,
  ADD COLUMN IF NOT EXISTS stage_lead_interesado_entrada  DATE,
  ADD COLUMN IF NOT EXISTS stage_lead_interesado_salida   DATE,
  ADD COLUMN IF NOT EXISTS stage_calendario_entrada       DATE,
  ADD COLUMN IF NOT EXISTS stage_calendario_salida        DATE,
  ADD COLUMN IF NOT EXISTS stage_agendo_visita_entrada    DATE,
  ADD COLUMN IF NOT EXISTS stage_agendo_visita_salida     DATE,
  ADD COLUMN IF NOT EXISTS stage_hot_entrada              DATE,
  ADD COLUMN IF NOT EXISTS stage_hot_salida               DATE,
  ADD COLUMN IF NOT EXISTS stage_seguimiento_entrada      DATE,
  ADD COLUMN IF NOT EXISTS stage_seguimiento_salida       DATE,
  ADD COLUMN IF NOT EXISTS stage_cierre_ganado_entrada    DATE,
  ADD COLUMN IF NOT EXISTS stage_cierre_ganado_salida     DATE,
  ADD COLUMN IF NOT EXISTS stage_cierre_perdido_entrada   DATE,
  ADD COLUMN IF NOT EXISTS stage_cierre_perdido_salida    DATE;
