# Deployment Runbook - GHL Analytics Platform

Version: 1.0.0 | Fecha: Mayo 2026

Runbook paso a paso desde "VPS recien aprovisionado" hasta "go-live".
Tiempo estimado total: 4-6 horas.

---

## Prerequisitos

- VPS Hostinger con Ubuntu 22.04+ (minimo 4 vCPU, 8GB RAM, 80GB SSD)
- Dominio configurado con acceso a DNS
- Cuenta de GHL con permisos de Agency Admin
- Cuenta de Meta Developer (opcional, para CTWA)
- Acceso SSH al VPS

---

## FASE 1 - Instalar EasyPanel (30 min)

```bash
# Conectar al VPS via SSH
ssh root@TU_IP_VPS

# Instalar EasyPanel
curl -sSL https://get.easypanel.io | sh

# EasyPanel levanta en el puerto 3000
# Acceder a: http://TU_IP_VPS:3000
# Crear usuario admin en el primer acceso
```

---

## FASE 2 - Configurar DNS (15 min)

En tu proveedor de DNS, crear los registros A:

| Subdominio | Tipo | Valor |
|---|---|---|
| `n8n.tudominio.com` | A | IP_DEL_VPS |
| `analytics.tudominio.com` | A | IP_DEL_VPS |
| `kuma.tudominio.com` | A | IP_DEL_VPS |

Esperar propagacion (1-30 min). Verificar: `nslookup n8n.tudominio.com`

---

## FASE 3 - Crear el stack en EasyPanel (45 min)

### 3.1 Crear el proyecto

1. Abrir EasyPanel UI en http://TU_IP_VPS:3000
2. Click en **New Project** -> Nombre: `ghl-analytics`
3. Click en **Add Service** -> Docker Compose
4. Pegar el contenido de `infra/docker-compose.yml`

### 3.2 Configurar Secret Manager

En EasyPanel -> Service -> cada servicio -> Environment, agregar las variables usando Secret Manager para las marcadas [SECRETO]:

**PostgreSQL:**
```
POSTGRES_DB=ghl_analytics
POSTGRES_USER=ghl_user
POSTGRES_PASSWORD=[SECRETO - generar con: openssl rand -base64 32]
PGDATA=/var/lib/postgresql/data
```

**n8n:**
```
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=[SECRETO]
N8N_HOST=n8n.tudominio.com
N8N_PROTOCOL=https
WEBHOOK_URL=https://n8n.tudominio.com/
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n_internal
DB_POSTGRESDB_USER=n8n_user
DB_POSTGRESDB_PASSWORD=[SECRETO]
N8N_ENCRYPTION_KEY=[SECRETO - openssl rand -base64 32]
GHL_API_KEY=[SECRETO - de GHL Agency Settings -> API Keys]
GHL_LOCATION_IDS=loc_id1,loc_id2
WEBHOOK_SECRET=[SECRETO - openssl rand -base64 32]
META_CLOUD_API_TOKEN=[SECRETO - opcional]
META_VERIFY_TOKEN=[SECRETO - openssl rand -hex 16]
EXECUTIONS_DATA_SAVE_ON_ERROR=all
EXECUTIONS_DATA_MAX_AGE=168
```

**Metabase:**
```
MB_DB_TYPE=postgres
MB_DB_HOST=postgres
MB_DB_PORT=5432
MB_DB_DBNAME=metabase_app
MB_DB_USER=metabase_user
MB_DB_PASS=[SECRETO]
MB_SITE_URL=https://analytics.tudominio.com
MB_EMBEDDING_SECRET_KEY=[SECRETO - openssl rand -base64 48]
JAVA_TIMEZONE=America/Bogota
MB_SEND_EMAIL_ON_FIRST_LOGIN=false
```

**Sistema:**
```
DOMAIN=tudominio.com
LETSENCRYPT_EMAIL=admin@tudominio.com
```

### 3.3 Levantar contenedores en orden

Desde EasyPanel, levantar en este orden (esperar healthy entre cada uno):

1. `postgres` (esperar: healthy)
2. `n8n` (esperar: running)
3. `metabase` (esperar: running - tarda 3-5 min en inicializar)
4. `traefik` (esperar: running)
5. `uptime-kuma` (esperar: running)

Verificar:
```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
# Todos deben mostrar "Up ... (healthy)" o "Up ..."
```

---

## FASE 4 - Inicializar schema de BD (20 min)

Conectar a PostgreSQL y ejecutar los scripts de init en orden:

```bash
# Conectar al contenedor de postgres
docker exec -it postgres psql -U ghl_user -d ghl_analytics

# Ejecutar scripts en orden (copiar y pegar o ejecutar desde fuera):
docker exec -i postgres psql -U ghl_user -d ghl_analytics < db/init/00_extensions.sql
docker exec -i postgres psql -U ghl_user -d ghl_analytics < db/init/01_roles.sql
docker exec -i postgres psql -U ghl_user -d ghl_analytics < db/init/02_dim_contacts.sql
docker exec -i postgres psql -U ghl_user -d ghl_analytics < db/init/03_dim_opportunities.sql
docker exec -i postgres psql -U ghl_user -d ghl_analytics < db/init/04_dim_conversations.sql
docker exec -i postgres psql -U ghl_user -d ghl_analytics < db/init/05_dim_pipelines_ads.sql
docker exec -i postgres psql -U ghl_user -d ghl_analytics < db/init/06_fact_messages.sql
docker exec -i postgres psql -U ghl_user -d ghl_analytics < db/init/07_fact_history_email.sql
docker exec -i postgres psql -U ghl_user -d ghl_analytics < db/init/08_fact_ctwa_clicks.sql
docker exec -i postgres psql -U ghl_user -d ghl_analytics < db/init/09_sync_state.sql
docker exec -i postgres psql -U ghl_user -d ghl_analytics < db/init/10_indexes.sql
docker exec -i postgres psql -U ghl_user -d ghl_analytics < db/init/11_rls_policies.sql
docker exec -i postgres psql -U ghl_user -d ghl_analytics < db/init/12_mv_unified_attribution.sql
docker exec -i postgres psql -U ghl_user -d ghl_analytics < db/init/13_pg_cron.sql
```

Verificar tablas:
```bash
docker exec postgres psql -U ghl_user -d ghl_analytics -c "\dt"
# Debe mostrar: dim_contacts, dim_opportunities, dim_conversations, dim_pipelines,
# dim_ads, fact_messages, fact_opp_stage_history, fact_email_events, fact_ctwa_clicks,
# ghl_sync_state
```

---

## FASE 5 - Configurar Metabase (30 min)

### 5.1 Setup inicial

1. Abrir https://analytics.tudominio.com
2. Completar el wizard de setup inicial
3. En "Add your data" -> seleccionar "I'll do this later"

### 5.2 Crear conexiones de BD

1. Admin -> Databases -> Add database -> PostgreSQL

**Conexion Sixteam Admin:**
- Name: `Sixteam Admin`
- Host: `postgres`
- Port: `5432`
- Database name: `ghl_analytics`
- Username: `sixteam_admin`
- Password: [de Secret Manager]

2. Guardar y verificar conexion (icono verde)

### 5.3 Crear grupos y permisos

Ver `metabase/groups_permissions.md` para instrucciones detalladas.

Crear en orden:
1. Grupo "Administradores Sixteam"
2. Grupo "Analistas Sixteam"

### 5.4 Recrear los 6 dashboards

Los dashboards se recrean manualmente usando los archivos en `metabase/dashboards/`.
Para cada dashboard:
1. Admin -> New -> Dashboard
2. Crear cada card con el SQL del archivo `metabase/queries/*.sql` correspondiente
3. Configurar parametros (location_id, date_from, date_to)
4. Configurar layout segun `size` en el JSON del dashboard

Ver `metabase/embedding_setup.md` para configurar embeddings JWT.
Ver `metabase/db_connections.md` para conexiones por cliente.

---

## FASE 6 - Importar workflows n8n (20 min)

1. Abrir https://n8n.tudominio.com
2. Login con N8N_BASIC_AUTH_USER / N8N_BASIC_AUTH_PASSWORD
3. Menu -> Import from file
4. Importar cada archivo de `n8n/workflows/` en orden:
   - WF-01 a WF-06 (webhooks)
   - WF-07 a WF-09 (polling)
   - WF-10 a WF-12 (CTWA, email, health)
   - WF-AI_enricher
5. Para cada workflow: configurar las credenciales de PostgreSQL (host: `postgres`, user: `n8n_writer`)
6. Activar todos los workflows

---

## FASE 7 - Registrar webhooks en GHL (15 min)

En GHL: Agency -> Location -> Settings -> Integrations -> Webhooks

Para cada subaccount cliente, crear webhooks apuntando a:

| Evento | URL del webhook |
|---|---|
| ContactCreate, ContactUpdate | `https://n8n.tudominio.com/ghl/contacts` |
| OpportunityCreate, OpportunityUpdate | `https://n8n.tudominio.com/ghl/opportunities` |
| ConversationUpdate | `https://n8n.tudominio.com/ghl/conversations` |
| AppointmentCreate, AppointmentUpdate | `https://n8n.tudominio.com/ghl/appointments` |

En cada webhook:
- Secret: el mismo valor que WEBHOOK_SECRET en las env vars
- Metodo: POST
- Content-Type: application/json

---

## FASE 8 - Configurar Meta Cloud API (opcional, 30 min)

Solo necesario si el cliente usa anuncios CTWA.

1. Abrir Meta for Developers -> App -> WhatsApp -> Configuration
2. En "Callback URL": `https://n8n.tudominio.com/meta/ctwa`
3. En "Verify token": el valor de META_VERIFY_TOKEN
4. Click "Verify and save"
5. Suscribir a: `messages`
6. En n8n verificar que WF-06 responde el challenge correctamente

---

## FASE 9 - Validacion final: Tests de aceptacion

```bash
# Instalar dependencias de test
apt-get install -y jq bc

# Copiar y configurar el entorno de test
cp .env.example .env
# Editar .env con los valores de produccion

# Correr la suite completa
cd tests/
./run_all.sh

# Para solo los tests BLOQUEANTES
./run_all.sh --skip-non-blocking
```

### Criterios Go / No-Go

**GO (desplegar a produccion):**
- Todos los tests BLOQUEANTES pasan (exit code 0)
- Al menos 1 cliente tiene datos fluyendo (ver logs n8n)
- Metabase muestra datos en los 6 dashboards

**NO-GO (no desplegar):**
- Cualquier test BLOQUEANTE falla
- RLS no aisla datos entre clientes (SEC-01)
- Datos no persisten tras reinicio (INFRA-02)
- RAM supera 3GB (PERF-05)

---

## Rollback

Si algo falla durante el despliegue:

```bash
# Detener todos los contenedores
docker compose down

# Si la BD tiene datos parciales, restaurar desde backup
docker exec postgres psql -U sixteam_admin -d ghl_analytics \
  -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
# Luego re-ejecutar los scripts de init
```
