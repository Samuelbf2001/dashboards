# GHL Analytics Platform — Guía de Despliegue en EasyPanel

**Versión:** 1.0.0 | **Plataforma:** EasyPanel 2.x sobre VPS Hostinger

---

## Requisitos previos

- VPS Hostinger con EasyPanel instalado y acceso SSH
- Dominio configurado con registros DNS A apuntando al IP del VPS:
  - `n8n.tudominio.com`
  - `analytics.tudominio.com`
  - `uptime.tudominio.com`
- Puerto 80 y 443 abiertos en el firewall del VPS
- Mínimo 4 GB de RAM recomendado (PERF-05: < 3 GB en operación normal)

---

## Fase 1 — Preparar el repositorio en el VPS

```bash
# Conectar al VPS via SSH
ssh root@<IP_VPS>

# Clonar el repositorio en la ubicación estándar de EasyPanel
cd /srv/easypanel/projects
git clone https://github.com/sixteam/ghl-analytics-platform.git ghl-analytics
cd ghl-analytics
```

---

## Fase 2 — Configurar variables de entorno en EasyPanel Secret Manager

En EasyPanel → Proyecto → Service → **Environment**:

1. Ir a la sección **Secrets** (variables marcadas `[SECRET]` en `.env.example`).
2. Crear cada secreto individualmente:

| Variable | Descripción |
|---|---|
| `POSTGRES_PASSWORD` | Contraseña de PostgreSQL — mínimo 32 caracteres aleatorios |
| `DB_POSTGRESDB_PASSWORD` | Contraseña del usuario `n8n_user` en PostgreSQL |
| `N8N_BASIC_AUTH_PASSWORD` | Contraseña de la UI de n8n |
| `N8N_ENCRYPTION_KEY` | 32 bytes hex: `openssl rand -hex 32` |
| `GHL_API_KEY` | API Key de GoHighLevel nivel Agency |
| `WEBHOOK_SECRET` | Secret HMAC para webhooks GHL: `openssl rand -hex 32` |
| `META_CLOUD_API_TOKEN` | Token de Meta Cloud API (si usa CTWA) |
| `META_VERIFY_TOKEN` | Token de verificación Meta (si usa CTWA) |
| `MB_DB_PASS` | Contraseña de Metabase en PostgreSQL |
| `MB_EMBEDDING_SECRET_KEY` | 32 bytes hex: `openssl rand -hex 32` |

3. Las variables no-secretas se configuran directamente en el campo **Environment Variables**:

```env
DOMAIN=tudominio.com
LETSENCRYPT_EMAIL=admin@tudominio.com
POSTGRES_DB=ghl_analytics
POSTGRES_USER=ghl_user
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_HOST=n8n.tudominio.com
WEBHOOK_URL=https://n8n.tudominio.com/
DB_POSTGRESDB_DATABASE=n8n_internal
DB_POSTGRESDB_USER=n8n_user
GHL_LOCATION_IDS=loc_id1,loc_id2
MB_DB_DBNAME=metabase_app
MB_DB_USER=metabase_user
MB_SITE_URL=https://analytics.tudominio.com
JAVA_TIMEZONE=America/Bogota
```

---

## Fase 3 — Extensiones de PostgreSQL (CRÍTICO)

El contenedor `postgres:16-alpine` no incluye `pgvector` ni `pg_cron` por defecto.
La imagen oficial **sí soporta** `pg_cron` como extensión pre-instalada a partir de PostgreSQL 16.

**IMPORTANTE:** el `docker-compose.yml` ya pasa el flag necesario:

```yaml
command: >
  postgres
    -c shared_preload_libraries=pg_cron
    -c cron.database_name=${POSTGRES_DB}
```

Para `pgvector`, la imagen `postgres:16-alpine` no lo incluye. Opciones:

**Opción A (recomendada):** Usar imagen con pgvector pre-instalado:
```yaml
# En docker-compose.yml, cambiar la imagen de postgres por:
image: pgvector/pgvector:pg16
```
Esta imagen es oficial de pgvector y equivalente a `postgres:16` con la extensión incluida.

**Opción B:** Construir imagen personalizada con un `Dockerfile`:
```dockerfile
FROM postgres:16-alpine
RUN apk add --no-cache git make gcc musl-dev && \
    git clone --branch v0.7.0 https://github.com/pgvector/pgvector.git && \
    cd pgvector && make && make install
```

Los scripts SQL en `db/init/` ejecutan `CREATE EXTENSION IF NOT EXISTS pgvector` — fallarán si la extensión no está disponible en la imagen.

---

## Fase 4 — Crear el stack en EasyPanel

1. EasyPanel → **New Project** → nombre: `ghl-analytics`
2. En el proyecto → **Services** → **Add Service** → **Docker Compose**
3. Pegar el contenido de `infra/docker-compose.yml`
4. Confirmar que los volúmenes se mapearon correctamente:
   - `postgres_data` → persistencia de BD
   - `postgres_backups` → backups diarios
   - `n8n_data` → workflows y credenciales de n8n
   - `metabase_data` → estado de Metabase
   - `kuma_data` → configuración de Uptime Kuma
   - `traefik_certs` → certificados Let's Encrypt

---

## Fase 5 — Primer arranque y verificación del schema

```bash
# Levantar todos los servicios
docker compose up -d

# Verificar que los 5 contenedores estén healthy
docker ps --format "table {{.Names}}\t{{.Status}}"

# Verificar que los scripts SQL se ejecutaron correctamente
docker exec -it ghl-analytics-postgres-1 \
  psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "\dt"

# Debe listar: dim_contacts, dim_opportunities, dim_conversations,
# dim_pipelines, dim_ads, fact_messages, fact_opp_stage_history,
# fact_email_events, fact_ctwa_clicks, ghl_sync_state
```

**NOTA:** Los scripts en `db/init/` solo se ejecutan en el **primer arranque** (cuando el volumen `postgres_data` está vacío). Si ya hay datos, no se re-ejecutan.

---

## Fase 6 — Mapear dominios en EasyPanel

Para cada servicio expuesto, en EasyPanel → Service → **Domains**:

| Servicio | Dominio |
|---|---|
| n8n | `n8n.tudominio.com` |
| metabase | `analytics.tudominio.com` |
| uptime-kuma | `uptime.tudominio.com` |

EasyPanel gestiona los labels de Traefik automáticamente si se usa su UI de dominios. Si se usa el `docker-compose.yml` directamente, los labels ya están configurados.

---

## Fase 7 — Configurar Uptime Kuma

1. Acceder a `https://uptime.tudominio.com`
2. Crear monitor para cada servicio:

| Monitor | URL | Intervalo |
|---|---|---|
| n8n Health | `https://n8n.tudominio.com/healthz` | 15 min |
| Metabase Health | `https://analytics.tudominio.com/api/health` | 15 min |
| PostgreSQL | TCP `postgres:5432` (desde contenedor) | 15 min |
| Traefik | `https://n8n.tudominio.com` (prueba de HTTPS) | 15 min |

---

## Fase 8 — Configurar backup automático

El script `infra/backup/pg_backup.sh` debe ejecutarse desde el contenedor `postgres` o desde el host:

```bash
# Opción A: Cron en el host (recomendada para EasyPanel)
# Editar crontab del root en el host:
crontab -e
# Agregar la línea del archivo infra/backup/crontab.example

# Opción B: Copiar script al volumen y ejecutar desde dentro del contenedor
docker cp infra/backup/pg_backup.sh ghl-analytics-postgres-1:/backups/
docker exec ghl-analytics-postgres-1 chmod +x /backups/pg_backup.sh

# Prueba manual del backup:
docker exec -e POSTGRES_DB=${POSTGRES_DB} \
            -e POSTGRES_USER=${POSTGRES_USER} \
            -e POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
  ghl-analytics-postgres-1 /backups/pg_backup.sh
```

---

## Fase 9 — Importar workflows de n8n

1. Acceder a `https://n8n.tudominio.com` con las credenciales configuradas
2. Settings → **Import from file** → importar cada JSON de `n8n/workflows/`
3. Configurar credenciales de PostgreSQL en n8n:
   - Host: `postgres`, Puerto: `5432`
   - Database: `ghl_analytics`
   - User: `n8n_writer` (rol de escritura, no el user principal)
   - Password: la contraseña del rol `n8n_writer` configurada en `01_roles.sql`

---

## Verificación de tests de aceptación

### INFRA-01 — Todos los servicios healthy

```bash
docker ps --filter "health=healthy" | grep -c "healthy"
# Debe retornar 5
```

### INFRA-02 — Persistencia entre reinicios

```bash
# Insertar fila de prueba
docker exec -it ghl-analytics-postgres-1 \
  psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} \
  -c "INSERT INTO ghl_sync_state VALUES ('test', 'test_loc', NOW(), NULL, 0, NULL, NOW())"

# Reiniciar el contenedor
docker restart ghl-analytics-postgres-1

# Verificar que la fila persiste
docker exec -it ghl-analytics-postgres-1 \
  psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} \
  -c "SELECT * FROM ghl_sync_state WHERE entity = 'test'"
# Debe retornar 1 fila

# Limpiar
docker exec -it ghl-analytics-postgres-1 \
  psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} \
  -c "DELETE FROM ghl_sync_state WHERE entity = 'test'"
```

### INFRA-03 — HTTPS en todos los dominios

```bash
curl -I https://n8n.tudominio.com/healthz
# Esperar: HTTP/2 200 + cert válido (no expired, no self-signed)

curl -I https://analytics.tudominio.com/api/health
# Esperar: HTTP/2 200

curl -I https://uptime.tudominio.com
# Esperar: HTTP/2 200
```

### INFRA-04 — Sin secretos hardcodeados

```bash
# Desde la raíz del repositorio:
grep -rn "password\|secret\|api_key\|token" \
  --include="*.js" --include="*.py" --include="*.sh" \
  --include="*.yml" --include="*.yaml" \
  | grep -v "example\|template\|SECRET_MANAGER\|CAMBIAR_POR\|\${" \
  | grep -vi "comment\|#"
# No debe retornar ninguna línea con valores reales hardcodeados
```

### INFRA-05 — Backup automático

```bash
# Ejecutar backup manual y verificar el archivo generado
docker exec -e POSTGRES_DB=${POSTGRES_DB} \
            -e POSTGRES_USER=${POSTGRES_USER} \
            -e POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
  ghl-analytics-postgres-1 /backups/pg_backup.sh

ls -lh $(docker volume inspect ghl-analytics_postgres_backups \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['Mountpoint'])")
# Debe mostrar el archivo YYYY-MM-DD.dump recién creado
```

### INFRA-06 — Uptime Kuma detecta caída

```bash
# Detener el contenedor de n8n
docker stop ghl-analytics-n8n-1

# Esperar hasta 2 minutos y verificar en Uptime Kuma UI que el monitor
# de n8n cambia a estado DOWN con alerta generada.

# Restaurar
docker start ghl-analytics-n8n-1
```

### SEC-01 — RLS: cliente A no ve datos de cliente B

```bash
# Requiere haber ejecutado client_provision_template.sql para dos clientes
docker exec -it ghl-analytics-postgres-1 psql -d ghl_analytics \
  -c "SET ROLE client_loc_<SLUG_A>; SELECT COUNT(*) FROM dim_contacts WHERE location_id = '<LOC_ID_B>';"
# Debe retornar 0
```

### SEC-02 — RLS: superadmin ve todos los datos

```bash
docker exec -it ghl-analytics-postgres-1 psql -U sixteam_admin -d ghl_analytics \
  -c "SELECT COUNT(*) FROM dim_contacts;"
# Debe retornar el total de filas de todos los clientes
```

### SEC-07 — Metabase sin acceso anónimo

```bash
curl -X POST https://analytics.tudominio.com/api/dataset \
  -H "Content-Type: application/json" \
  -d '{"database": 1, "type": "native", "native": {"query": "SELECT 1"}}'
# Debe retornar 401 Unauthorized
```

### SEC-09 — n8n UI requiere autenticación

```bash
curl -I https://n8n.tudominio.com/
# Debe retornar 401 Unauthorized
```

---

## Restore de backup

```bash
# Listar contenido del dump sin restaurar:
pg_restore --list /backups/2026-05-16.dump

# Restaurar a una BD de destino:
pg_restore \
  -h postgres -p 5432 -U ghl_user \
  -d ghl_analytics \
  --no-owner --role=ghl_user \
  /backups/2026-05-16.dump

# NOTA: si restauras sobre una BD existente, agregar --clean para
# eliminar objetos antes de recrearlos (precaución en producción).
```

---

## Troubleshooting común

| Síntoma | Causa probable | Solución |
|---|---|---|
| Scripts SQL no se ejecutaron | Volumen `postgres_data` ya existe con datos | Borrar volumen y reiniciar: `docker volume rm ghl-analytics_postgres_data` |
| `pg_cron` no programa el refresh | `shared_preload_libraries` no cargado | Verificar el `command:` en docker-compose.yml |
| `CREATE EXTENSION pgvector` falla | Imagen `postgres:16-alpine` no tiene pgvector | Cambiar a imagen `pgvector/pgvector:pg16` |
| Certificado SSL no generado | Puerto 80 bloqueado o DNS no propagado | Verificar firewall y TTL del DNS |
| n8n no conecta a PostgreSQL | BD `n8n_internal` no existe | Crearla manualmente: `CREATE DATABASE n8n_internal;` |
| Vista materializada no refresca | `pg_cron` no está en `shared_preload_libraries` | Ver fila en `cron.job` y logs de PostgreSQL |
