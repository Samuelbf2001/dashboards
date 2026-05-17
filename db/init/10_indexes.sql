-- ─────────────────────────────────────────────────────────────────────────────
-- 10_indexes.sql — Índices de rendimiento
-- Los índices parciales WHERE is_current=TRUE son los más importantes:
-- cubren el 99% de los queries de analytics que solo necesitan la versión activa.
-- Los índices GIN cubren búsquedas por tag o campo custom de JSONB.
-- Los índices ivfflat cubren búsqueda semántica con pgvector.
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── dim_contacts ─────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_contacts_contact_id
  ON dim_contacts(contact_id);

CREATE INDEX IF NOT EXISTS idx_contacts_location
  ON dim_contacts(location_id);

-- Índices parciales sobre is_current=TRUE (versión vigente del contacto)
CREATE INDEX IF NOT EXISTS idx_contacts_email
  ON dim_contacts(email) WHERE is_current;

CREATE INDEX IF NOT EXISTS idx_contacts_phone
  ON dim_contacts(phone) WHERE is_current;

CREATE INDEX IF NOT EXISTS idx_contacts_current
  ON dim_contacts(contact_id) WHERE is_current;

CREATE INDEX IF NOT EXISTS idx_contacts_utm_campaign
  ON dim_contacts(utm_campaign_first) WHERE is_current;

CREATE INDEX IF NOT EXISTS idx_contacts_utm_source
  ON dim_contacts(utm_source_first) WHERE is_current;

CREATE INDEX IF NOT EXISTS idx_contacts_created
  ON dim_contacts(ghl_created_at DESC) WHERE is_current;

-- Índices GIN para búsqueda por tag específico o campo custom de JSONB
CREATE INDEX IF NOT EXISTS idx_contacts_tags
  ON dim_contacts USING GIN(tags) WHERE is_current;

CREATE INDEX IF NOT EXISTS idx_contacts_custom_fields
  ON dim_contacts USING GIN(custom_fields) WHERE is_current;

-- Índice ivfflat para búsqueda semántica de contactos por similitud de embedding
-- lists=100 es adecuado para datasets de hasta ~500k vectores (ajustar en producción)
CREATE INDEX IF NOT EXISTS idx_contacts_embedding
  ON dim_contacts USING ivfflat(embedding vector_cosine_ops)
  WITH (lists = 100)
  WHERE embedding IS NOT NULL AND is_current;

-- ─── dim_opportunities ────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_opps_opp_id
  ON dim_opportunities(opportunity_id);

CREATE INDEX IF NOT EXISTS idx_opps_contact
  ON dim_opportunities(contact_id) WHERE is_current;

CREATE INDEX IF NOT EXISTS idx_opps_location
  ON dim_opportunities(location_id) WHERE is_current;

CREATE INDEX IF NOT EXISTS idx_opps_pipeline
  ON dim_opportunities(pipeline_id) WHERE is_current;

CREATE INDEX IF NOT EXISTS idx_opps_stage
  ON dim_opportunities(pipeline_stage_id) WHERE is_current;

CREATE INDEX IF NOT EXISTS idx_opps_status
  ON dim_opportunities(status) WHERE is_current;

CREATE INDEX IF NOT EXISTS idx_opps_current
  ON dim_opportunities(opportunity_id) WHERE is_current;

CREATE INDEX IF NOT EXISTS idx_opps_created
  ON dim_opportunities(ghl_created_at DESC) WHERE is_current;

-- ─── dim_conversations ────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_conv_conv_id
  ON dim_conversations(conversation_id);

CREATE INDEX IF NOT EXISTS idx_conv_contact
  ON dim_conversations(contact_id) WHERE is_current;

CREATE INDEX IF NOT EXISTS idx_conv_location
  ON dim_conversations(location_id) WHERE is_current;

CREATE INDEX IF NOT EXISTS idx_conv_channel
  ON dim_conversations(channel_type) WHERE is_current;

CREATE INDEX IF NOT EXISTS idx_conv_status
  ON dim_conversations(status) WHERE is_current;

CREATE INDEX IF NOT EXISTS idx_conv_last_msg
  ON dim_conversations(last_message_at DESC) WHERE is_current;

CREATE INDEX IF NOT EXISTS idx_conv_reply_time
  ON dim_conversations(first_reply_seconds) WHERE is_current;

CREATE INDEX IF NOT EXISTS idx_conv_current
  ON dim_conversations(conversation_id) WHERE is_current;

-- Índice ivfflat para búsqueda semántica de conversaciones similares
CREATE INDEX IF NOT EXISTS idx_conv_embedding
  ON dim_conversations USING ivfflat(embedding vector_cosine_ops)
  WITH (lists = 100)
  WHERE embedding IS NOT NULL AND is_current;

-- ─── dim_pipelines ────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_pipelines_pipeline_id
  ON dim_pipelines(pipeline_id);

CREATE INDEX IF NOT EXISTS idx_pipelines_stage_id
  ON dim_pipelines(stage_id);

-- ─── dim_ads ──────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_ads_campaign_id
  ON dim_ads(campaign_id);

CREATE INDEX IF NOT EXISTS idx_ads_adset_id
  ON dim_ads(adset_id);

-- ─── fact_messages ────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_msg_conversation
  ON fact_messages(conversation_id);

CREATE INDEX IF NOT EXISTS idx_msg_contact
  ON fact_messages(contact_id);

CREATE INDEX IF NOT EXISTS idx_msg_location
  ON fact_messages(location_id);

CREATE INDEX IF NOT EXISTS idx_msg_direction
  ON fact_messages(direction, sent_at DESC);

-- Índices parciales para correlación con fact_email_events y WhatsApp Cloud API
CREATE INDEX IF NOT EXISTS idx_msg_email_msg_id
  ON fact_messages(email_message_id) WHERE email_message_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_msg_wa_msg_id
  ON fact_messages(wa_message_id) WHERE wa_message_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_msg_sent_at
  ON fact_messages(sent_at DESC);

-- Índice ivfflat para búsqueda semántica de mensajes por tema
CREATE INDEX IF NOT EXISTS idx_msg_embedding
  ON fact_messages USING ivfflat(embedding vector_cosine_ops)
  WITH (lists = 100)
  WHERE embedding IS NOT NULL;

-- ─── fact_opp_stage_history ───────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_opp_hist_opp_id
  ON fact_opp_stage_history(opportunity_id);

CREATE INDEX IF NOT EXISTS idx_opp_hist_contact
  ON fact_opp_stage_history(contact_id);

CREATE INDEX IF NOT EXISTS idx_opp_hist_location
  ON fact_opp_stage_history(location_id);

CREATE INDEX IF NOT EXISTS idx_opp_hist_changed_at
  ON fact_opp_stage_history(changed_at DESC);

CREATE INDEX IF NOT EXISTS idx_opp_hist_pipeline
  ON fact_opp_stage_history(pipeline_id);

CREATE INDEX IF NOT EXISTS idx_opp_hist_to_stage
  ON fact_opp_stage_history(to_stage_id);

-- ─── fact_email_events ────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_email_evt_message_id
  ON fact_email_events(message_id);

CREATE INDEX IF NOT EXISTS idx_email_evt_contact
  ON fact_email_events(contact_id);

CREATE INDEX IF NOT EXISTS idx_email_evt_location
  ON fact_email_events(location_id);

CREATE INDEX IF NOT EXISTS idx_email_evt_type
  ON fact_email_events(event_type);

CREATE INDEX IF NOT EXISTS idx_email_evt_occurred_at
  ON fact_email_events(occurred_at DESC);

-- ─── fact_ctwa_clicks ─────────────────────────────────────────────────────────
-- Nota: ctwa_clid tiene UNIQUE constraint — ya tiene índice implícito
CREATE INDEX IF NOT EXISTS idx_ctwa_phone
  ON fact_ctwa_clicks(phone);

CREATE INDEX IF NOT EXISTS idx_ctwa_ad_id
  ON fact_ctwa_clicks(ad_id);

CREATE INDEX IF NOT EXISTS idx_ctwa_campaign_id
  ON fact_ctwa_clicks(campaign_id);

-- Índice parcial: clicks aún no correlacionados con un contacto (para WF-11)
CREATE INDEX IF NOT EXISTS idx_ctwa_not_correlated
  ON fact_ctwa_clicks(phone) WHERE contact_id IS NULL;

CREATE INDEX IF NOT EXISTS idx_ctwa_contact_id
  ON fact_ctwa_clicks(contact_id) WHERE contact_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_ctwa_clicked_at
  ON fact_ctwa_clicks(clicked_at DESC);
