-- ─────────────────────────────────────────────────────────────────────────────
-- 06_fact_messages.sql — Tabla de Mensajes (Hecho append-only)
-- Mensajes individuales de todas las conversaciones.
-- Tabla append-only: nunca se modifica, solo se inserta.
-- Granularidad más fina del sistema — cada fila es un único mensaje.
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── fact_messages ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fact_messages (
  id               BIGSERIAL        PRIMARY KEY,

  -- ID único de GHL — UNIQUE constraint previene duplicados en upsert
  message_id       VARCHAR(50)      NOT NULL UNIQUE,

  -- FK lógica a dim_conversations
  conversation_id  VARCHAR(50)      NOT NULL,

  -- FK lógica a dim_contacts — desnormalizado para evitar JOIN extra en analytics
  contact_id       VARCHAR(50)      NOT NULL,

  -- Subaccount GHL — clave de RLS por cliente
  location_id      VARCHAR(50)      NOT NULL,

  -- ─── Tipo y dirección ────────────────────────────────────────────────────
  message_type     VARCHAR(30),     -- TEXT | EMAIL | WHATSAPP | SMS | CALL | VOICEMAIL | ACTIVITY
  direction        VARCHAR(10)      NOT NULL, -- inbound (del contacto) | outbound (asesor o bot)

  -- ─── Cuerpo del mensaje ──────────────────────────────────────────────────
  body             TEXT,            -- Fuente para embeddings y análisis de IA
  subject          VARCHAR(500),    -- Asunto del email (solo message_type=EMAIL)

  -- ─── Campos de email ─────────────────────────────────────────────────────
  from_email       VARCHAR(255),
  to_email         VARCHAR(255),
  -- Message-ID SMTP — clave de correlación con fact_email_events
  email_message_id VARCHAR(200),

  -- ─── Campos de llamada ───────────────────────────────────────────────────
  call_duration_sec INT,            -- Duración en segundos (solo message_type=CALL)
  call_status      VARCHAR(30),     -- answered | missed | voicemail | busy

  -- ─── Campos de WhatsApp ──────────────────────────────────────────────────
  wa_message_id    VARCHAR(200),    -- ID del mensaje en WhatsApp Cloud API
  wa_status        VARCHAR(20),     -- sent | delivered | read | failed

  -- ─── Usuario emisor ──────────────────────────────────────────────────────
  user_id          VARCHAR(50),     -- ID del usuario GHL que envió (si outbound)
  user_name        VARCHAR(200),    -- Desnormalizado

  -- ─── Campos de Inteligencia Artificial ───────────────────────────────────
  ai_intent        VARCHAR(100),    -- ask_price | confirm_appointment | objection | closing
  ai_sentiment     VARCHAR(20),     -- positive | neutral | negative
  ai_is_question   BOOLEAN,         -- TRUE si el mensaje contiene una pregunta
  ai_entities      JSONB,           -- Entidades extraídas: fechas, montos, productos, ubicaciones

  -- Embedding del cuerpo para búsqueda semántica de conversaciones por tema
  embedding        vector(1536),

  -- ─── Timestamp ───────────────────────────────────────────────────────────
  sent_at          TIMESTAMPTZ      NOT NULL
);

COMMENT ON TABLE fact_messages IS
  'Tabla append-only de mensajes individuales de GHL. '
  'message_id UNIQUE previene duplicados. '
  'email_message_id correlaciona con fact_email_events para rastrear opens/clicks.';
