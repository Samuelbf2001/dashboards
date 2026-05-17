# GHL Analytics Platform — Plan de Implementación Maestro

**Versión:** 1.0.0
**Fecha:** Mayo 2026
**Basado en:** GHL_Analytics_Platform_Spec_v1.docx + GHL_Analytics_Database_Design_v1.docx
**Modo de ejecución:** 3 agentes Sonnet en paralelo + supervisor/integrador (Opus)

---

## 1. Objetivo

Construir, en este repositorio, **todos los artefactos versionables** de la GHL Analytics Platform — la plataforma self-hosted de inteligencia de datos para Sixteam que centraliza GoHighLevel + Meta CTWA + ESP en un warehouse PostgreSQL con dashboards Metabase.

Esta entrega es el **bundle de implementación completo** que se desplegará en EasyPanel sobre el VPS Hostinger existente.

## 2. Alcance del entregable

Cuatro capas, divididas entre tres agentes:

| Capa | Agente | Entregables |
|------|--------|-------------|
| Infraestructura + BD | Agente 1 | docker-compose, configuración Traefik, schema SQL completo, RLS, índices, vista materializada, pg_cron, scripts de seed/roles |
| ETL n8n | Agente 2 | 12 workflows JSON versionados, código de sanitización, lógica SCD2, validación HMAC, manejador CTWA + Meta CAPI, AI enricher |
| Metabase + QA + Docs | Agente 3 | Definiciones de 6 dashboards, SQL de KPIs, scripts de test (INFRA, SEC, ETL, MB, PERF), runbook de despliegue, guía de operación |

## 3. Estructura del repositorio

```
ghl-analytics-platform/
├── IMPLEMENTATION_PLAN.md         ← este documento
├── README.md                      ← generado por Agente 3
├── .env.example                   ← Agente 1
├── infra/
│   ├── docker-compose.yml         ← Agente 1
│   ├── traefik/
│   │   └── dynamic/
│   │       ├── cors.yml
│   │       └── ratelimit.yml
│   └── easypanel/
│       └── DEPLOYMENT.md
├── db/
│   ├── init/
│   │   ├── 00_extensions.sql      ← Agente 1
│   │   ├── 01_roles.sql
│   │   ├── 02_dim_contacts.sql
│   │   ├── 03_dim_opportunities.sql
│   │   ├── 04_dim_conversations.sql
│   │   ├── 05_dim_pipelines_ads.sql
│   │   ├── 06_fact_messages.sql
│   │   ├── 07_fact_history_email.sql
│   │   ├── 08_fact_ctwa_clicks.sql
│   │   ├── 09_sync_state.sql
│   │   ├── 10_indexes.sql
│   │   ├── 11_rls_policies.sql
│   │   ├── 12_mv_unified_attribution.sql
│   │   └── 13_pg_cron.sql
│   ├── migrations/
│   │   └── README.md
│   └── seed/
│       └── client_provision_template.sql
├── n8n/
│   ├── workflows/                 ← Agente 2 (12 JSON files)
│   │   ├── WF-01_ghl_webhook_contacts.json
│   │   ├── WF-02_ghl_webhook_opportunities.json
│   │   ├── WF-03_ghl_webhook_conversations.json
│   │   ├── WF-04_ghl_webhook_appointments.json
│   │   ├── WF-05_meta_ctwa_receiver.json
│   │   ├── WF-06_meta_ctwa_verify.json
│   │   ├── WF-07_polling_contacts.json
│   │   ├── WF-08_polling_opportunities.json
│   │   ├── WF-09_polling_appointments.json
│   │   ├── WF-10_esp_email_events.json
│   │   ├── WF-11_ctwa_enricher.json
│   │   ├── WF-12_health_check.json
│   │   └── WF-AI_enricher.json
│   ├── lib/
│   │   ├── sanitize.js
│   │   ├── scd2.js
│   │   ├── hmac_validator.js
│   │   └── meta_capi.js
│   └── README.md
├── metabase/                      ← Agente 3
│   ├── dashboards/
│   │   ├── 01_agency_master.json
│   │   ├── 02_pipeline.json
│   │   ├── 03_contacts.json
│   │   ├── 04_conversations.json
│   │   ├── 05_ctwa_meta_ads.json
│   │   └── 06_appointments.json
│   ├── queries/
│   │   └── *.sql                  ← SQL parametrizado de cada card
│   ├── groups_permissions.md
│   └── embedding_setup.md
├── tests/                         ← Agente 3
│   ├── infra/
│   ├── security/
│   ├── etl/
│   ├── metabase/
│   ├── perf/
│   └── run_all.sh
└── docs/                          ← Agente 3
    ├── DEPLOYMENT_RUNBOOK.md
    ├── OPERATIONS_GUIDE.md
    ├── CLIENT_ONBOARDING.md
    └── TROUBLESHOOTING.md
```

## 4. División de trabajo entre agentes

### Agente 1 — Infraestructura + Base de Datos

**Misión:** Que un operador pueda hacer `docker compose up -d` en EasyPanel y obtener PostgreSQL + n8n + Metabase + Traefik + Uptime Kuma corriendo con HTTPS, schema completo, RLS activado y vista materializada refrescándose vía pg_cron.

**Cubre fases 1 y 2** del spec (Infraestructura Base + Schema y RLS).

**Tests que debe pasar:** INFRA-01..06, SEC-01, SEC-02, SEC-07, SEC-09.

**Restricciones críticas:**
- PostgreSQL 16-alpine con extensiones `pgvector`, `pg_cron`, `uuid-ossp`
- Cada cliente = un rol PostgreSQL aislado vía RLS (template parametrizable)
- `sixteam_admin` = BYPASSRLS; `n8n_writer` = escritura con policy permisiva; `client_loc_xxx` = SELECT solo de su `location_id`
- Backup `pg_dump` automático diario a volumen persistente
- Variables sensibles via EasyPanel Secret Manager — nunca hardcoded
- Traefik con cert resolver Let's Encrypt + middlewares `cors-strict` y `ratelimit`
- Vista materializada `mv_unified_attribution` con refresh CONCURRENTLY cada hora

### Agente 2 — ETL n8n Workflows

**Misión:** Que al importar los 12 JSON en n8n y configurar credenciales, la plataforma capture y normalice eventos de GHL + Meta CTWA + ESP en tiempo real (<10s) con doble track webhook+polling y sin duplicados.

**Cubre fases 3, 4 y 5** del spec (Webhooks + Polling + CTWA/Email).

**Tests que debe pasar:** ETL-01..12, SEC-04, SEC-05, SEC-06, SEC-10.

**Restricciones críticas:**
- 12 workflows con propósito único (no mezclar ingestión con transformación)
- Upsert por PK natural con `ON CONFLICT DO UPDATE` — idempotente entre webhook y polling
- SCD Tipo 2 en `dim_contacts` y `dim_opportunities` con la lógica del spec
- `fact_opp_stage_history` append-only — capturado solo del webhook OpportunityUpdate
- Sanitización obligatoria de TODO input en Code node antes de cualquier query
- Validación HMAC `X-GHL-Signature` y challenge Meta `hub.challenge`
- Polling con cursor `last_synced_at` por `(entity, location_id)` en `ghl_sync_state`
- Rate limit outbound a GHL API: 80 req / 10s con backoff exponencial
- WF-11 correlaciona `ctwa_clid` ↔ `contact_id` por número E.164 normalizado
- Envío de eventos a Meta CAPI cuando una oportunidad CTWA llega a `won`
- AI enricher async cada 15 min — nunca bloquea el pipeline principal

### Agente 3 — Metabase + QA + Documentación

**Misión:** Que al conectar Metabase a PostgreSQL existan los 6 dashboards funcionales con RLS por cliente, un set completo de tests ejecutables (que validen los criterios BLOQUEANTE del spec) y un runbook que un operador junior pueda seguir para desplegar y operar la plataforma.

**Cubre fases 6, 7 y 8** del spec (Dashboards + QA + Producción).

**Tests que debe pasar:** MB-01..10, PERF-01..05 + script ejecutor de TODAS las categorías.

**Restricciones críticas:**
- 6 dashboards obligatorios (Agency Master, Pipeline, Contactos, Conversaciones, CTWA, Citas)
- Cada SQL de card es un archivo .sql versionado (no inline en JSON)
- Filtro `{{location_id}}` parametrizado para que admin Sixteam pueda comparar clientes
- Cliente externo: conexión de BD dedicada con su rol — RLS hace el resto, no se filtra por SQL
- Tests categorizados (INFRA, SEC, ETL, MB, PERF) ejecutables vía `tests/run_all.sh`
- Cada test marcado BLOQUEANTE en el spec debe tener su check automatizado
- Runbook con orden exacto de fases 1→8 y comandos copy-paste

## 5. Stack tecnológico fijado

| Componente | Versión | Notas |
|------------|---------|-------|
| PostgreSQL | 16-alpine | Con pgvector + pg_cron + uuid-ossp |
| n8n | latest (1.x) | DB postgresdb separada `n8n_internal` |
| Metabase OSS | latest (0.51.x) | DB separada `metabase_app`, timezone America/Bogota |
| Traefik | 3.x | Cert resolver letsencrypt, middlewares globales |
| Uptime Kuma | latest | Health checks cada 15 min |
| Node.js (n8n Code) | 20 LTS | runtime de sanitización y SCD2 |

## 6. Variables de entorno requeridas

Configuradas en EasyPanel → Service → Environment. Las marcadas `[SECRET]` van en Secret Manager.

### Postgres
`POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD [SECRET]`, `PGDATA`

### n8n
`N8N_BASIC_AUTH_USER`, `N8N_BASIC_AUTH_PASSWORD [SECRET]`, `N8N_HOST`, `WEBHOOK_URL`, `N8N_ENCRYPTION_KEY [SECRET]`, `DB_POSTGRESDB_*`, `GHL_API_KEY [SECRET]`, `GHL_LOCATION_IDS`, `WEBHOOK_SECRET [SECRET]`, `META_CLOUD_API_TOKEN [SECRET]`, `META_VERIFY_TOKEN [SECRET]`

### Metabase
`MB_DB_*`, `MB_SITE_URL`, `MB_EMBEDDING_SECRET_KEY [SECRET]`, `JAVA_TIMEZONE=America/Bogota`

### Sistema
`DOMAIN`, `LETSENCRYPT_EMAIL`

## 7. Criterios de aceptación globales (BLOQUEANTES)

Para considerar el sistema **listo para producción**, los siguientes tests deben pasar:

- **Infraestructura:** INFRA-01, 02, 03, 04, 05
- **Seguridad:** SEC-01, 02, 03, 04, 05, 06, 07, 09, 10
- **ETL:** ETL-01, 02, 03, 04, 05, 06, 07, 08, 09, 10
- **Metabase:** MB-01, 02, 03, 04, 05, 06, 07, 09
- **Performance:** PERF-01, 02, 05

(Tests no-bloqueantes pueden fallar en go-live pero deben estar implementados.)

## 8. Plan de fases (referencia del spec)

| Fase | Días | Agente principal |
|------|------|------------------|
| 1 — Infraestructura Base | 3 | 1 |
| 2 — Schema y RLS | 2 | 1 |
| 3 — Ingestión Webhooks | 5 | 2 |
| 4 — Polling e Historial | 3 | 2 |
| 5 — CTWA y Email Events | 4 | 2 |
| 6 — Dashboards Metabase | 5 | 3 |
| 7 — QA y Tests Completos | 3 | 3 |
| 8 — Producción | 1 | 3 + supervisor |

## 9. Contrato entre agentes (interfaces compartidas)

Para que los tres agentes trabajen en paralelo sin colisionar, fijamos contratos:

### 9.1 Tablas y columnas
Los nombres de tablas/columnas vienen del Database Design v1 y son **inmutables**. Cualquier desviación rompe los otros agentes.

### 9.2 Roles PostgreSQL
- `sixteam_admin` — Agente 1 lo crea, Agente 3 lo usa para conexión "Sixteam Admin" en Metabase
- `n8n_writer` — Agente 1 lo crea, Agente 2 lo usa en credenciales de n8n
- `client_loc_<xxx>` — template parametrizable creado por Agente 1, instanciado por cliente al onboarding

### 9.3 Rutas de webhook
- `/ghl/contacts`, `/ghl/opportunities`, `/ghl/conversations`, `/ghl/appointments` — n8n
- `/meta/ctwa` (POST + GET) — n8n
- `/esp/events` — n8n

Agente 1 abre rutas en Traefik; Agente 2 implementa los workflows que las atienden.

### 9.4 Vista materializada
`mv_unified_attribution` es creada por Agente 1, consumida por Agente 3 en dashboards. Su contrato de columnas es el del Database Design (no añadir/quitar sin sincronizar).

## 10. Rol del supervisor (Opus)

1. Lanza los 3 agentes en paralelo con prompts auto-contenidos.
2. Revisa cada entregable contra los criterios de aceptación y los contratos de la sección 9.
3. Integra: ajusta colisiones de nombres, rutas, variables de entorno.
4. Genera el README final y verifica que el bundle entregado sea desplegable end-to-end.
5. Produce un reporte de integración con: qué se entregó, qué tests están listos, qué pendientes quedan, próximos pasos para go-live real.
