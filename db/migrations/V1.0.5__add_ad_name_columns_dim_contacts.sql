-- ─────────────────────────────────────────────────────────────────────────────
-- V1.0.5 — Agregar ad_name_first / ad_name_last a dim_contacts
--
-- GHL expone attributionSource.adName para leads CTWA.
-- Estos nombres también quedan disponibles para UTM fb/ig vía JOIN con dim_ads.
-- Columnas añadidas en producción el 2026-05-21 vía script; esta migración las
-- formaliza para que nuevos entornos partan del mismo schema.
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE dim_contacts
  ADD COLUMN IF NOT EXISTS ad_name_first VARCHAR(500),
  ADD COLUMN IF NOT EXISTS ad_name_last  VARCHAR(500);

CREATE INDEX IF NOT EXISTS idx_dim_contacts_ad_name_first
  ON dim_contacts(ad_name_first)
  WHERE ad_name_first IS NOT NULL;
