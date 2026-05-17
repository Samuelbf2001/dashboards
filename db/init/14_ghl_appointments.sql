-- ─── 14_ghl_appointments.sql ─────────────────────────────────────────────────
-- Tabla de citas de GHL
--
-- NOTA ARQUITECTURAL: El Database Design v1 no define esta tabla explícitamente
-- (las demás tablas usan prefijo dim_*/fact_*). Se usa "ghl_appointments" según
-- la nomenclatura del Platform Spec v1.0.0 sección 6. Esta tabla usa upsert
-- simple (no SCD2) dado que las citas tienen ciclo de vida corto y GHL expone
-- su estado actual vía API sin historial de versiones relevante para BI.
--
-- Consumidores:
--   - n8n WF-04 (webhook ContactAppointment*)
--   - n8n WF-09 (polling cada 4h)
--   - Dashboard 06_appointments en Metabase
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ghl_appointments (
  id               BIGSERIAL       PRIMARY KEY,
  appointment_id   VARCHAR(50)     NOT NULL UNIQUE,    -- ID natural de GHL
  contact_id       VARCHAR(50)     NOT NULL,            -- FK lógica a dim_contacts
  location_id      VARCHAR(50)     NOT NULL,            -- Clave RLS por cliente
  calendar_id      VARCHAR(50),                         -- ID del calendario en GHL
  title            VARCHAR(500),
  -- Estado del ciclo de vida de la cita
  -- Valores conocidos de GHL: booked, confirmed, cancelled, showed, noshow, no_show
  status           VARCHAR(30),
  start_time       TIMESTAMPTZ,
  end_time         TIMESTAMPTZ,
  assigned_user_id VARCHAR(50),
  assigned_user_name VARCHAR(200),                      -- Desnormalizado para BI
  notes            TEXT,
  address          VARCHAR(500),
  ghl_created_at   TIMESTAMPTZ,
  ghl_updated_at   TIMESTAMPTZ,
  synced_at        TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- ─── ÍNDICES ────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_appt_appointment_id   ON ghl_appointments(appointment_id);
CREATE INDEX IF NOT EXISTS idx_appt_contact_id       ON ghl_appointments(contact_id);
CREATE INDEX IF NOT EXISTS idx_appt_location_id      ON ghl_appointments(location_id);
CREATE INDEX IF NOT EXISTS idx_appt_start_time       ON ghl_appointments(start_time DESC);
CREATE INDEX IF NOT EXISTS idx_appt_status           ON ghl_appointments(status);
CREATE INDEX IF NOT EXISTS idx_appt_user_id          ON ghl_appointments(assigned_user_id);

-- ─── ROW LEVEL SECURITY ──────────────────────────────────────────────────────
ALTER TABLE ghl_appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE ghl_appointments FORCE ROW LEVEL SECURITY;

-- n8n_writer puede escribir sin restricción (política permisiva)
CREATE POLICY rls_appt_writer ON ghl_appointments
  FOR ALL TO n8n_writer
  USING (TRUE)
  WITH CHECK (TRUE);

-- Sixteam admin bypasea RLS (BYPASSRLS configurado en 01_roles.sql)
-- No requiere policy explícita.

-- Template de policy por cliente — reemplazar 'abc123' y 'client_loc_abc123'
-- por el location_id y slug real. Ver db/seed/client_provision_template.sql
--
-- CREATE POLICY rls_appt_abc123 ON ghl_appointments
--   FOR ALL TO client_loc_abc123
--   USING (location_id = 'abc123');
