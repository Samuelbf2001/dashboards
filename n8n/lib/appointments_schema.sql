-- appointments_schema.sql
-- Fallback DDL para la tabla ghl_appointments
--
-- ATENCION: El Database Design v1 NO define una tabla ghl_appointments ni dim_appointments.
-- WF-04 y WF-09 usan una tabla propia de citas. Este archivo provee el DDL de fallback.
-- Si Agente 1 ya creo esta tabla con estructura compatible, NO ejecutar este archivo.
--
-- Inconsistencia detectada:
--   - GHL_Platform.txt seccion 6 lista "ghl_appointments" con prefijo ghl_*
--   - GHL_Database.txt usa nomenclatura dim_*/fact_* para todas las demas tablas
--   - ghl_appointments NO aparece en el Database Design v1
--   - Se crea con prefijo ghl_ (nombre del Platform Spec) pero con patron de columnas
--     coherente con el resto del warehouse. El supervisor debe decidir si renombrar.
--
-- Referencias: GHL_Platform.txt seccion 6 (tabla ghl_appointments)

CREATE TABLE IF NOT EXISTS ghl_appointments (
  id               BIGSERIAL PRIMARY KEY,
  appointment_id   VARCHAR(50)   NOT NULL UNIQUE,
  contact_id       VARCHAR(50)   NOT NULL,
  location_id      VARCHAR(50)   NOT NULL,
  calendar_id      VARCHAR(50),
  title            VARCHAR(500),
  status           VARCHAR(30),        -- booked, confirmed, cancelled, showed, noshow
  start_time       TIMESTAMPTZ,
  end_time         TIMESTAMPTZ,
  assigned_user_id VARCHAR(50),
  notes            TEXT,
  address          VARCHAR(500),
  ghl_created_at   TIMESTAMPTZ,
  ghl_updated_at   TIMESTAMPTZ,
  synced_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- Indices de rendimiento
CREATE INDEX IF NOT EXISTS idx_appt_appointment_id ON ghl_appointments(appointment_id);
CREATE INDEX IF NOT EXISTS idx_appt_contact_id     ON ghl_appointments(contact_id);
CREATE INDEX IF NOT EXISTS idx_appt_location_id    ON ghl_appointments(location_id);
CREATE INDEX IF NOT EXISTS idx_appt_start_time     ON ghl_appointments(start_time DESC);
CREATE INDEX IF NOT EXISTS idx_appt_status         ON ghl_appointments(status);

-- Row Level Security
ALTER TABLE ghl_appointments ENABLE ROW LEVEL SECURITY;

-- Policy permisiva para n8n_writer (escritura sin restriccion)
CREATE POLICY rls_appt_writer ON ghl_appointments
  FOR ALL TO n8n_writer USING (TRUE) WITH CHECK (TRUE);

-- Comentario: agregar policies por cliente siguiendo el patron de db/init/11_rls_policies.sql
-- Ejemplo:
-- CREATE POLICY rls_appt_abc123 ON ghl_appointments
--   FOR ALL TO client_loc_abc123
--   USING (location_id = 'abc123');
