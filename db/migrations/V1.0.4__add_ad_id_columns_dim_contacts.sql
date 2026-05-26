-- ─────────────────────────────────────────────────────────────────────────────
-- V1.0.4 — Agregar ad_id y ctwa_clid a dim_contacts
-- GHL expone attributionSource.adId y ctwaClid para leads CTWA.
-- Estos campos no estaban capturados en los workflows WF-01 y WF-07.
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE dim_contacts
  ADD COLUMN IF NOT EXISTS ad_id_first     VARCHAR(100),
  ADD COLUMN IF NOT EXISTS ad_id_last      VARCHAR(100),
  ADD COLUMN IF NOT EXISTS ctwa_clid_first VARCHAR(500),
  ADD COLUMN IF NOT EXISTS ctwa_clid_last  VARCHAR(500);

CREATE INDEX IF NOT EXISTS idx_dim_contacts_ad_id_first
  ON dim_contacts(ad_id_first)
  WHERE ad_id_first IS NOT NULL;

-- Verificacion:
-- SELECT contact_id, ad_id_first, ad_id_last, ctwa_clid_first
-- FROM dim_contacts WHERE ad_id_first IS NOT NULL LIMIT 10;
