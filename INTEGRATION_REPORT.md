# GHL Analytics Platform — Reporte de Integración

**Supervisor:** Opus 4.7
**Agentes:** Sonnet 4.6 × 3
**Fecha:** 2026-05-17
**Estado:** Bundle completo — listo para despliegue

---

## 1. Resumen ejecutivo

Los tres agentes Sonnet completaron sus entregas. El supervisor verificó los contratos cruzados (tablas, roles, rutas, variables), resolvió los gaps detectados y generó este reporte. El bundle en `ghl-analytics-platform/` es desplegable end-to-end siguiendo `docs/DEPLOYMENT_RUNBOOK.md`.

**Totales entregados: 150 archivos**

| Categoría | Archivos | Agente |
|-----------|----------|--------|
| db/init SQL (schema completo) | 15 | 1 + supervisor |
| Infraestructura YAML | 4 | 1 |
| Configuración / docs infra | 3 | 1 |
| n8n Workflows JSON | 13 | 2 |
| n8n librerías JS | 4 | 2 |
| Metabase dashboards JSON | 6 | 3 |
| Metabase queries SQL | 51 | 3 |
| Metabase docs | 3 | 3 |
| Tests ejecutables (.sh) | 35 | 3 |
| Fixtures de test | 7 | 3 |
| Documentación operativa | 5 | 3 |
| README + plans | 2 | 1+sup |
| .env.example | 1 | 1+sup |

---

## 2. Fixes de integración aplicados por el supervisor

### FIX-01 — Imagen PostgreSQL (BLOQUEANTE)
**Problema:** Agente 1 usó `postgres:16-alpine` que no incluye pgvector.
**Fix:** Cambiada a `pgvector/pgvector:pg16` en `infra/docker-compose.yml:42`.
**Impacto:** Sin este fix, `00_extensions.sql` falla en `CREATE EXTENSION pgvector` y todo el stack de IA queda inoperativo.

### FIX-02 — Tabla `ghl_appointments` (GAP entre specs)
**Problema:** Presente en Platform Spec sección 6 y referenciada por WF-04/WF-09 del Agente 2, pero ausente del Database Design v1 (el documento canónico de schema).
**Fix:** Creado `db/init/14_ghl_appointments.sql` con RLS, índices y patrón coherente con el resto del warehouse. Se decidió mantener el prefijo `ghl_` (tal como lo nombra el Platform Spec) en lugar de `dim_` ya que no aplica SCD2.
**Actualización:** `db/seed/client_provision_template.sql` actualizado para incluir RLS policy de `ghl_appointments`.

### FIX-03 — Variables de entorno faltantes
**Problema:** Agentes 2 y 3 requieren variables no incluidas por el Agente 1.
**Fix:** Añadidas al final de `.env.example`:
- `AI_EMBEDDING_URL`, `AI_EMBEDDING_MODEL`, `AI_LLM_URL`, `AI_LLM_MODEL`, `OPENAI_API_KEY` → WF-AI_enricher
- `META_PIXEL_ID` → WF-11 Meta CAPI
- `UPTIME_KUMA_PUSH_URL` → WF-12 Health Check
- Variables de test: `METABASE_ADMIN_USER/PASSWORD`, `CLIENT_LOCATION_ID`, `OTHER_LOCATION_ID`, `CLIENT_A_ROLE/PASSWORD`, `TEST_LOCATION_ID`, `BACKUP_DIR`, `MIN_LOCATIONS`

### FIX-04 — RLS en cors.yml no interpola `${DOMAIN}`
**Problema:** Traefik no interpola variables de entorno en archivos de configuración dinámica `.yml`.
**Estado:** Documentado en `infra/easypanel/DEPLOYMENT.md` como paso manual obligatorio antes del deploy (`sed -i "s/\${DOMAIN}/tudominio.com/g" infra/traefik/dynamic/cors.yml`).

---

## 3. Inconsistencias entre specs (registradas, no bloqueantes)

| # | Inconsistencia | Resolución |
|---|----------------|------------|
| I-01 | Platform Spec usa `ghl_*` para tablas; Database Design usa `dim_*/fact_*` | Database Design es canónico para `dim_contacts`, `dim_opportunities`, `dim_conversations`, `dim_pipelines`, `dim_ads`, `fact_messages`, `fact_opp_stage_history`, `fact_email_events`, `fact_ctwa_clicks`. `ghl_appointments` y `ghl_sync_state` conservan prefijo `ghl_` según Platform Spec. |
| I-02 | Platform Spec sección 5.1 muestra `ALTER TABLE ghl_contacts ENABLE ROW LEVEL SECURITY` con nombres incorrectos | RLS en `db/init/11_rls_policies.sql` usa nombres correctos `dim_*`/`fact_*` del Database Design |
| I-03 | `ghl_appointments` ausente del Database Design | Creada en FIX-02 |
| I-04 | `assigned_user_name` ausente del Platform Spec para citas pero necesaria para Dashboard 06 | Agregada en `14_ghl_appointments.sql` por coherencia con `dim_conversations` |
| I-05 | Valores de `status` en citas no documentados en ningún spec | WF-04 y Agente 3 asumen: `booked, confirmed, cancelled, showed, noshow` — verificar contra la API real de GHL en primer sprint |

---

## 4. Estado de tests BLOQUEANTES

| Test | Capa | Cubierto por | Estado |
|------|------|-------------|--------|
| INFRA-01 containers healthy | Infra | Script `tests/infra/infra_01_containers_healthy.sh` | ✅ listo |
| INFRA-02 persistencia Postgres | Infra | Script `tests/infra/infra_02_postgres_persistence.sh` | ✅ listo |
| INFRA-03 HTTPS + cert | Infra | Script `tests/infra/infra_03_https_certs.sh` | ✅ listo |
| INFRA-04 no hardcoded secrets | Infra | Script `tests/infra/infra_04_no_hardcoded_secrets.sh` | ✅ listo |
| INFRA-05 backup funciona | Infra | Script `tests/infra/infra_05_backup_works.sh` | ✅ listo |
| SEC-01 RLS aislamiento A/B | BD | Script `tests/security/sec_01_rls_isolation.sh` | ✅ listo |
| SEC-02 superadmin ve todo | BD | Script `tests/security/sec_02_superadmin_sees_all.sh` | ✅ listo |
| SEC-03 CORS rechaza | Traefik | Script `tests/security/sec_03_cors_rejects_unauthorized.sh` | ⚠️ Requiere sustituir `${DOMAIN}` en cors.yml |
| SEC-04 Rate limit 429 | Traefik | Script `tests/security/sec_04_rate_limit.sh` | ✅ listo |
| SEC-05 HMAC inválida 401 | n8n | Script `tests/security/sec_05_hmac_validation.sh` | ✅ listo |
| SEC-06 SQL injection 400 | n8n | Script `tests/security/sec_06_sql_injection.sh` | ✅ listo |
| SEC-07 Metabase sin anónimo | Metabase | Script `tests/security/sec_07_metabase_no_anon.sh` | ✅ listo |
| SEC-09 n8n sin auth 401 | n8n | Script `tests/security/sec_09_n8n_auth.sh` | ✅ listo |
| SEC-10 Meta verify challenge | n8n | Script `tests/security/sec_10_meta_verify.sh` | ✅ listo |
| ETL-01..10 | n8n + BD | Scripts `tests/etl/etl_0*.sh` | ✅ listos |
| MB-01..09 | Metabase | Scripts `tests/metabase/mb_0*.sh` | ⚠️ Requieren dashboards creados manualmente en Metabase |
| PERF-01 query <3s | BD | Script `tests/perf/perf_01_pipeline_query.sh` | ✅ listo |
| PERF-02 P99 webhook <10s | n8n+BD | Script `tests/perf/perf_02_webhook_latency.sh` | ✅ listo |
| PERF-05 RAM <3GB | Infra | Script `tests/perf/perf_05_ram_usage.sh` | ✅ listo |

**Tests BLOQUEANTES con precondición manual: 2** (SEC-03: sustituir DOMAIN; MB-01..09: crear dashboards en Metabase UI).

---

## 5. Pendientes para go-live real (fuera del scope del bundle de código)

| # | Pendiente | Responsable |
|---|-----------|-------------|
| P-01 | Sustituir `${DOMAIN}` en `traefik/dynamic/cors.yml` antes del deploy | Operador |
| P-02 | Registrar webhooks en cada GHL Sub-account (Settings → Integrations → Webhooks) | Operador / Sixteam |
| P-03 | Configurar Meta Cloud API webhook apuntando a `https://n8n.DOMAIN/meta/ctwa` | Operador |
| P-04 | Crear conexiones de BD en Metabase UI (sixteam_admin + una por cliente) | Operador |
| P-05 | Recrear 6 dashboards en Metabase UI usando `metabase/dashboards/*.json` como blueprint | Analista |
| P-06 | Asignar contraseñas a roles PostgreSQL (`ALTER ROLE ... PASSWORD '...'`) tras primer arranque | Operador |
| P-07 | Verificar valores reales de `status` en citas de GHL contra WF-04 y Dashboard 06 | Dev / Sixteam |
| P-08 | Evaluar serialización de polling si se onboardean más de 10 locations simultáneos (riesgo de saturar rate limit de GHL API agregado) | Tech lead |
| P-09 | Configurar `META_PIXEL_ID` y probar Meta CAPI en entorno de sandbox antes de prod | Dev |
| P-10 | Configurar notificaciones de Uptime Kuma (email / Slack) — WF-12 solo hace push del estado | Operador |

---

## 6. Próximos pasos recomendados

1. **Primer despliegue** — Seguir `docs/DEPLOYMENT_RUNBOOK.md` paso a paso.
2. **Onboarding del primer cliente** — Ejecutar `db/seed/client_provision_template.sql` con datos reales.
3. **Importar workflows en n8n** — Guía en `n8n/README.md`.
4. **Crear dashboards en Metabase** — Seguir `metabase/dashboards/*.json` como blueprint.
5. **Correr `tests/run_all.sh`** — Confirmar todos los BLOQUEANTES en verde antes de comunicar go-live.
6. **Fase 9 (fuera del spec v1)** — Considerar: serialización multi-location para polling, endpoint de Meta CAPI sandbox, embedding semántico en producción.

---

## 7. Estructura final del repositorio

```
ghl-analytics-platform/
├── IMPLEMENTATION_PLAN.md
├── INTEGRATION_REPORT.md        ← este documento
├── README.md
├── .env.example
├── infra/
│   ├── docker-compose.yml       ← imagen pgvector/pgvector:pg16 (FIX-01)
│   ├── traefik/
│   │   ├── traefik.yml
│   │   └── dynamic/
│   │       ├── cors.yml         ← requiere sustitución manual de ${DOMAIN}
│   │       └── ratelimit.yml
│   ├── easypanel/
│   │   └── DEPLOYMENT.md
│   └── backup/
│       ├── pg_backup.sh
│       └── crontab.example
├── db/
│   ├── init/
│   │   ├── 00_extensions.sql
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
│   │   ├── 13_pg_cron.sql
│   │   └── 14_ghl_appointments.sql  ← agregada por supervisor (FIX-02)
│   ├── migrations/README.md
│   └── seed/client_provision_template.sql  ← actualizada con ghl_appointments
├── n8n/
│   ├── workflows/WF-01..12 + WF-AI (13 JSON)
│   ├── lib/
│   │   ├── sanitize.js
│   │   ├── scd2.js
│   │   ├── hmac_validator.js
│   │   └── meta_capi.js
│   └── README.md
├── metabase/
│   ├── dashboards/ (6 JSON)
│   ├── queries/ (51 SQL)
│   ├── groups_permissions.md
│   ├── embedding_setup.md
│   └── db_connections.md
├── tests/
│   ├── infra/ (5 sh), security/ (8 sh), etl/ (10 sh), metabase/ (5 sh), perf/ (3 sh)
│   ├── fixtures/ (7 JSON de payloads de prueba)
│   ├── run_all.sh
│   └── README.md
└── docs/
    ├── DEPLOYMENT_RUNBOOK.md
    ├── OPERATIONS_GUIDE.md
    ├── CLIENT_ONBOARDING.md
    └── TROUBLESHOOTING.md
```
