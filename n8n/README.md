# n8n ETL Workflows — GHL Analytics Platform

Agente 2 — ETL n8n Workflows  
Versión: 1.0.0 | Mayo 2026

---

## Arquitectura de los workflows

| ID | Nombre | Trigger | Responsabilidad |
|----|--------|---------|-----------------|
| WF-01 | GHL Webhook Contacts | POST /ghl/contacts | Valida HMAC → sanitiza → SCD2 upsert `dim_contacts` |
| WF-02 | GHL Webhook Opportunities | POST /ghl/opportunities | Valida HMAC → sanitiza → SCD2 upsert `dim_opportunities` + INSERT `fact_opp_stage_history` cuando cambia etapa |
| WF-03 | GHL Webhook Conversations | POST /ghl/conversations | Upsert `dim_conversations` + INSERT `fact_messages` + recalcula `first_reply_seconds` |
| WF-04 | GHL Webhook Appointments | POST /ghl/appointments | Valida HMAC → upsert `ghl_appointments` |
| WF-05 | Meta CTWA Receiver | POST /meta/ctwa | Extrae `ctwa_clid` + phone → INSERT `fact_ctwa_clicks` ON CONFLICT DO NOTHING |
| WF-06 | Meta CTWA Verify | GET /meta/ctwa | Responde `hub.challenge` si `hub.verify_token` coincide |
| WF-07 | Polling Contacts | Cron 60 min | Incremental GHL API → SCD2 upsert `dim_contacts` con cursor |
| WF-08 | Polling Opportunities | Cron 60 min | Incremental GHL API → SCD2 upsert `dim_opportunities` |
| WF-09 | Polling Appointments | Cron 4 h | Incremental GHL API → upsert `ghl_appointments` |
| WF-10 | ESP Email Events | POST /esp/events | Detecta Mailgun/SendGrid → INSERT `fact_email_events` ON CONFLICT DO NOTHING |
| WF-11 | CTWA Enricher | Cron 30 min | Correlaciona `ctwa_clid` ↔ `contact_id` por phone E.164; envía conversiones a Meta CAPI |
| WF-12 | Health Check Reporter | Cron 15 min | Pings a Postgres, n8n, Metabase → reporta a Uptime Kuma |
| WF-AI | AI Enricher | Cron 15 min | Genera embeddings y análisis LLM para `fact_messages` |

---

## Librerías JS reusables (n8n/lib/)

Los archivos en `n8n/lib/` se versionan en el repositorio pero **no se importan con `require()`** desde n8n porque el sandbox de Code nodes no soporta módulos del sistema de archivos. Para usarlos, copia el contenido de la función necesaria al inicio del Code node correspondiente.

| Archivo | Contenido |
|---------|-----------|
| `sanitize.js` | `sanitizeContact`, `sanitizeOpportunity`, `sanitizeConversation`, `sanitizeMessage`, `sanitizeAppointment`, `normalizeE164`, `validateEmail`, `validateGHLId`, `parseISODate` |
| `scd2.js` | `applySCD2`, `applySCD2Contact`, `applySCD2Opportunity` — lógica SCD Tipo 2 completa |
| `hmac_validator.js` | `validateGHLSignature`, `validateMetaSignature` — timing-safe HMAC-SHA256 |
| `meta_capi.js` | `sendConversionToMeta` — event_id determinístico para deduplicación |
| `appointments_schema.sql` | DDL fallback para `ghl_appointments` (ver sección de inconsistencias) |

---

## Prerequisitos

1. PostgreSQL 16 corriendo con el schema del Database Design v1 aplicado (Agente 1).
2. El rol `n8n_writer` creado con `GRANT INSERT, UPDATE, DELETE, SELECT ON ALL TABLES` (Agente 1).
3. n8n 1.x con acceso a internet para llamadas a GHL API, Meta Graph API y APIs de IA.
4. Traefik con rutas `/ghl/*`, `/meta/ctwa`, `/esp/events` configuradas (Agente 1).

---

## Importar workflows en n8n

### Via UI (recomendado para primer despliegue)

1. Abre n8n en tu navegador: `https://<N8N_HOST>`
2. Menu lateral → **Workflows** → botón **Import from file**
3. Selecciona cada archivo JSON de `n8n/workflows/` en orden numérico
4. Después de importar, activa cada workflow con el toggle en la esquina superior derecha

### Via n8n CLI (para CI/CD)

```bash
# Asegúrate de tener n8n CLI instalado globalmente o usa npx
n8n import:workflow --input=n8n/workflows/WF-01_ghl_webhook_contacts.json
n8n import:workflow --input=n8n/workflows/WF-02_ghl_webhook_opportunities.json
# ... repetir para cada archivo
```

### Via API REST de n8n

```bash
# Importar via API (requiere Basic Auth)
curl -X POST https://<N8N_HOST>/api/v1/workflows \
  -u "$N8N_BASIC_AUTH_USER:$N8N_BASIC_AUTH_PASSWORD" \
  -H "Content-Type: application/json" \
  -d @n8n/workflows/WF-01_ghl_webhook_contacts.json
```

---

## Configurar credenciales en n8n

Después de importar los workflows, configura las credenciales en **n8n → Settings → Credentials**:

### Credencial PostgreSQL (usada por todos los workflows)

- **Type:** PostgreSQL
- **Name:** `Postgres n8n_writer` (debe coincidir exactamente con el nombre en los workflows)
- **Host:** `postgres` (nombre del servicio Docker)
- **Port:** `5432`
- **Database:** `ghl_analytics`
- **User:** `n8n_writer`
- **Password:** `<POSTGRES_N8N_WRITER_PASSWORD>` (desde EasyPanel Secret Manager)
- **SSL:** desactivar dentro de la red Docker privada

### Variables de entorno requeridas

Configura en **EasyPanel → Service n8n → Environment**:

| Variable | Descripción | Obligatoria |
|----------|-------------|-------------|
| `GHL_API_KEY` | API Key de GHL nivel agencia | Sí |
| `GHL_LOCATION_IDS` | IDs de subaccounts separados por coma (ej: `loc1,loc2`) | Sí |
| `WEBHOOK_SECRET` | Secret para validar `X-GHL-Signature` HMAC-SHA256 | Sí |
| `META_CLOUD_API_TOKEN` | Token de acceso Meta Cloud API | Sí (para CTWA) |
| `META_VERIFY_TOKEN` | Token de verificación webhook Meta | Sí (para CTWA) |

### Variables adicionales (AI Enricher)

Reportadas al supervisor para agregar a `.env.example`:

| Variable | Descripción |
|----------|-------------|
| `AI_EMBEDDING_URL` | URL del endpoint de embeddings (default: OpenAI ada-002) |
| `AI_LLM_URL` | URL del endpoint LLM para intent/sentiment (default: OpenAI gpt-4o-mini) |
| `OPENAI_API_KEY` | API Key de OpenAI (si se usan los defaults de OpenAI) |
| `META_PIXEL_ID` | ID del Pixel de Meta para enviar conversion events via CAPI (WF-11) |
| `UPTIME_KUMA_PUSH_URL` | URL push de Uptime Kuma para WF-12 (ej: `http://kuma:3001/api/push/<token>`) |

---

## Activar webhooks en GHL

1. Entra a tu GHL Agency Dashboard → **Settings → Webhooks**
2. Crea los siguientes webhooks apuntando a tu n8n:

| Evento GHL | URL del webhook | Workflow |
|------------|-----------------|----------|
| ContactCreate, ContactUpdate | `https://<N8N_HOST>/webhook/ghl/contacts` | WF-01 |
| OpportunityCreate, OpportunityUpdate | `https://<N8N_HOST>/webhook/ghl/opportunities` | WF-02 |
| ConversationCreate, ConversationUpdate, InboundMessage, OutboundMessage | `https://<N8N_HOST>/webhook/ghl/conversations` | WF-03 |
| AppointmentCreate, AppointmentUpdate | `https://<N8N_HOST>/webhook/ghl/appointments` | WF-04 |

3. En GHL, copia el **Webhook Secret** que te genera y ponlo como `WEBHOOK_SECRET` en EasyPanel.

---

## Configurar webhook de Meta Cloud API (CTWA)

1. Ve a [Meta Developers](https://developers.facebook.com) → tu App → **WhatsApp → Configuration → Webhook**
2. Callback URL: `https://<N8N_HOST>/webhook/meta/ctwa`
3. Verify Token: el valor de `META_VERIFY_TOKEN` que configuraste en EasyPanel
4. Haz clic en **Verify and Save** — Meta hará un GET a `/webhook/meta/ctwa?hub.mode=subscribe&hub.challenge=...`
5. WF-06 responderá automáticamente con el challenge si el token coincide (test SEC-10)
6. Suscribirse a los campos: `messages` con sub-campos `referral`

---

## Troubleshooting común

### Error 401 en webhooks GHL
- Verifica que `WEBHOOK_SECRET` en EasyPanel coincida exactamente con el secreto configurado en GHL Webhooks.
- GHL envía el header como `X-GHL-Signature: sha256=<hex>` — verifica que el header no esté siendo removido por Traefik.

### Error 403 en verificación Meta CTWA
- `META_VERIFY_TOKEN` en EasyPanel debe ser idéntico al Verify Token configurado en Meta Developers.
- Asegúrate de que WF-06 esté activo antes de hacer la verificación en Meta.

### Polling no incremental (reprocesa todos los registros)
- Revisa la tabla `ghl_sync_state`: `SELECT * FROM ghl_sync_state;`
- Si `last_synced_at` es NULL, el polling hará un backfill completo (comportamiento esperado en la primera ejecución).
- Si `last_cursor` tiene un valor inválido, límpialo: `UPDATE ghl_sync_state SET last_cursor = NULL WHERE entity = 'contacts';`

### Duplicados en dim_contacts
- Verifica los índices: `\d dim_contacts` en psql.
- El upsert SCD2 no usa `ON CONFLICT` directo porque la PK es `surrogate_key` (BIGSERIAL). La deduplicación funciona buscando `WHERE contact_id = $1 AND is_current = TRUE` antes de insertar.
- Si se crean duplicados, busca: `SELECT contact_id, COUNT(*) FROM dim_contacts WHERE is_current = TRUE GROUP BY contact_id HAVING COUNT(*) > 1;`

### WF-11 no correlaciona ctwa_clid
- El match se hace por `phone` en E.164. Verifica que el contacto en GHL tenga teléfono normalizado.
- Ejecuta manualmente: `SELECT * FROM fact_ctwa_clicks WHERE contact_id IS NULL LIMIT 10;`
- Compara el phone de ctwa con `SELECT phone FROM dim_contacts WHERE is_current = TRUE LIMIT 20;`

### Meta CAPI no envía eventos
- Verifica que `META_PIXEL_ID` esté configurado en las variables de entorno de n8n.
- Revisa en `fact_ctwa_clicks`: `SELECT capi_sent_at, capi_event_id, capi_payload FROM fact_ctwa_clicks WHERE capi_sent_at IS NOT NULL LIMIT 5;`

---

## Verificación manual de tests ETL

### ETL-01: ContactCreate webhook upserta contacto
```bash
curl -X POST https://<N8N_HOST>/webhook/ghl/contacts \
  -H "Content-Type: application/json" \
  -H "X-GHL-Signature: sha256=<firma_calculada>" \
  -d '{"id":"testcontact01","locationId":"testlocation1","email":"test@gmail.com","phone":"3001234567","firstName":"Test"}'
# Verificar: SELECT * FROM dim_contacts WHERE contact_id = 'testcontact01';
```

### ETL-02: OpportunityUpdate escribe historial de etapa
```bash
# Enviar dos webhooks con pipeline_stage_id diferente
# Verificar: SELECT * FROM fact_opp_stage_history WHERE opportunity_id = '<id>';
```

### ETL-03: Idempotencia (mismo evento 3 veces = 1 fila)
```bash
# Enviar el mismo webhook 3 veces
# Verificar: SELECT COUNT(*) FROM dim_contacts WHERE contact_id = '<id>' AND is_current = TRUE;
# Debe devolver exactamente 1
```

### ETL-04: Polling incremental no reprocesa
```bash
# Tras primera ejecución de WF-07:
SELECT entity, location_id, last_synced_at, records_synced FROM ghl_sync_state WHERE entity = 'contacts';
# last_synced_at debe tener timestamp; segunda ejecucion debe incrementar records_synced solo con nuevos
```

### ETL-06: ctwa_clid capturado
```bash
curl -X POST https://<N8N_HOST>/webhook/meta/ctwa \
  -H "Content-Type: application/json" \
  -d '{"entry":[{"changes":[{"value":{"messages":[{"from":"573001234567","referral":{"ctwa_clid":"test_clid_001","source_url":"https://fb.me/ad","headline":"Promo"}}]}}]}]}'
# Verificar: SELECT * FROM fact_ctwa_clicks WHERE ctwa_clid = 'test_clid_001';
```

### ETL-09: Email sanitizado a lowercase
```bash
# Enviar contacto con email "TEST@GMAIL.COM"
# Verificar: SELECT email FROM dim_contacts WHERE contact_id = '<id>';
# Debe ser 'test@gmail.com'
```

### ETL-10: Teléfono normalizado E.164
```bash
# Enviar contacto con phone "3001234567"
# Verificar: SELECT phone FROM dim_contacts WHERE contact_id = '<id>';
# Debe ser '+573001234567'
```

### SEC-05: Firma HMAC inválida retorna 401
```bash
curl -X POST https://<N8N_HOST>/webhook/ghl/contacts \
  -H "Content-Type: application/json" \
  -H "X-GHL-Signature: sha256=000000000000000000000000000000000000000000000000" \
  -d '{"test": 1}'
# Debe retornar HTTP 500 (n8n error) o el flujo debe terminar sin insertar
# En producción configurar error handling para retornar 401 explícito
```

### SEC-10: Meta CTWA verify challenge
```bash
curl "https://<N8N_HOST>/webhook/meta/ctwa?hub.mode=subscribe&hub.challenge=123456&hub.verify_token=<META_VERIFY_TOKEN>"
# Debe retornar: 123456
```

---

## Nota sobre ghl_appointments

El Database Design v1 no define una tabla `ghl_appointments` ni `dim_appointments`. El Platform Spec sí la referencia como `ghl_appointments`. Se usa el nombre del Platform Spec. El DDL de fallback está en `n8n/lib/appointments_schema.sql`. Si Agente 1 ya creó esta tabla con estructura compatible, ignorar el archivo SQL de fallback.

---

## Nota sobre SCD2 en polling (WF-07/WF-08)

El polling aplica SCD2 completo para `dim_contacts` y `dim_opportunities`. Sin embargo, `fact_opp_stage_history` **nunca se escribe desde el polling** — solo se escribe desde WF-02 (webhook OpportunityUpdate). Esto es intencional: el polling no puede reconstruir el historial de cambios de etapa porque GHL no expone ese historial retroactivamente.

---

## Nota sobre roles PostgreSQL

Todos los nodos Postgres en los workflows usan la credencial `Postgres n8n_writer` que mapea al rol `n8n_writer` de PostgreSQL. Este rol tiene permiso de INSERT, UPDATE, DELETE, SELECT en todas las tablas y bypasea RLS mediante policy permisiva (`USING (TRUE) WITH CHECK (TRUE)`). Nunca exponer las credenciales de `n8n_writer` fuera del contenedor n8n.
