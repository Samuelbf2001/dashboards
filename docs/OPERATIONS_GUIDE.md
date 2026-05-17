# Operations Guide - GHL Analytics Platform

Guia de operacion dia a dia para el equipo de Sixteam.

---

## 1. Ver logs de cada servicio

### PostgreSQL
```bash
docker logs postgres --tail 100 -f
# Buscar: ERROR, FATAL, connection refused
```

### n8n (workflows y ejecuciones)
```bash
docker logs n8n --tail 100 -f
# Buscar: Error, Failed, Timeout
```

Ejecuciones fallidas en la UI:
- Abrir https://n8n.tudominio.com
- Menu -> Executions
- Filtrar por "Failed"
- Click en la ejecucion para ver el nodo que fallo y el mensaje de error

### Metabase
```bash
docker logs metabase --tail 100 -f
# Buscar: ERROR, Exception, OutOfMemory
```

### Traefik
```bash
docker logs traefik --tail 100 -f
# Buscar: error, connection refused, certificate
```

---

## 2. Troubleshooting de workflow fallido

### Pasos generales
1. Ir a n8n -> Executions -> Failed
2. Abrir la ejecucion fallida
3. El nodo rojo indica donde fallo
4. Ver el tab "Output" del nodo anterior para ver los datos que llegaron
5. Ver el tab "Error" del nodo fallido para el mensaje exacto

### Reintentar una ejecucion fallida
En n8n UI -> Executions -> click en la ejecucion fallida -> boton "Retry"

### Reintentar webhooks fallidos manualmente
Si un webhook GHL no fue procesado:
1. En GHL: Settings -> Integrations -> Webhooks -> Event Log
2. Buscar el evento fallido
3. Click "Retry"

Para webhooks de Meta CTWA, no hay retry automatico en Meta. Usar los fixtures en `tests/fixtures/sample_payloads/ctwa_meta_webhook.json` para simular el evento.

---

## 3. Monitoreo de espacio en disco y PostgreSQL

### Espacio en disco del VPS
```bash
df -h
# /dev/sda1 no debe superar el 80% de uso
```

### Tamano de la BD y tablas principales
```bash
docker exec postgres psql -U sixteam_admin -d ghl_analytics -c "
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 15;"
```

### Monitoreo de RAM de los containers
```bash
docker stats --no-stream
# Verificar que la suma no supere 3GB
```

### Conexiones activas a PostgreSQL
```bash
docker exec postgres psql -U sixteam_admin -d ghl_analytics -c "
SELECT COUNT(*), state FROM pg_stat_activity GROUP BY state;"
```

---

## 4. Restaurar desde backup

### Listar backups disponibles
```bash
ls -lh /var/backups/postgres/
# Los archivos .dump estan ordenados por fecha
```

### Restaurar un backup especifico
```bash
BACKUP_FILE=/var/backups/postgres/ghl_analytics_20261015_030000.dump

# Detener n8n y Metabase primero para evitar escrituras
docker stop n8n metabase

# Restaurar
docker exec -i postgres pg_restore \
  -U sixteam_admin \
  -d ghl_analytics \
  --clean \
  --if-exists \
  < "${BACKUP_FILE}"

# Refrescar vista materializada
docker exec postgres psql -U sixteam_admin -d ghl_analytics \
  -c "REFRESH MATERIALIZED VIEW mv_unified_attribution;"

# Reiniciar servicios
docker start n8n metabase
```

### Verificar integridad del backup
```bash
docker exec -i postgres pg_restore \
  -U sixteam_admin \
  --list \
  < "${BACKUP_FILE}" | head -20
```

---

## 5. Rotar credenciales

### Rotar password de sixteam_admin
```bash
# 1. Generar nueva contrasena
NEW_PASS=$(openssl rand -base64 32)

# 2. Cambiar en PostgreSQL
docker exec postgres psql -U sixteam_admin -d ghl_analytics \
  -c "ALTER ROLE sixteam_admin PASSWORD '${NEW_PASS}';"

# 3. Actualizar en EasyPanel Secret Manager -> POSTGRES_PASSWORD
# 4. Actualizar en Metabase: Admin -> Databases -> Sixteam Admin -> Edit -> Save
# 5. Reiniciar Metabase
docker restart metabase
```

### Rotar WEBHOOK_SECRET
```bash
NEW_SECRET=$(openssl rand -base64 32)
# 1. Actualizar en EasyPanel: WEBHOOK_SECRET = NEW_SECRET
# 2. Reiniciar n8n: docker restart n8n
# 3. Actualizar en TODOS los webhooks de GHL (Settings -> Integrations -> Webhooks)
```

### Rotar MB_EMBEDDING_SECRET_KEY
```bash
NEW_KEY=$(openssl rand -base64 48)
# 1. Actualizar en EasyPanel: MB_EMBEDDING_SECRET_KEY = NEW_KEY
# 2. Reiniciar Metabase: docker restart metabase
# 3. IMPORTANTE: todos los tokens JWT embebidos existentes dejan de funcionar
#    Notificar a los portales de cliente para regenerar sus URLs de embed
```

---

## 6. Escalar verticalmente (Hostinger)

Si el VPS necesita mas recursos:

1. Ir a Hostinger Dashboard -> VPS -> tu instancia -> Upgrade
2. Seleccionar el plan superior (ej: de 4 vCPU/8GB a 6 vCPU/16GB)
3. La IP publica se mantiene
4. Tiempo de downtime: 5-10 minutos

Ajustes post-escala:
```bash
# Aumentar max_connections de PostgreSQL si se necesita
docker exec postgres psql -U sixteam_admin -c "
  ALTER SYSTEM SET max_connections = 200;
  SELECT pg_reload_conf();"

# Aumentar heap de Metabase (en docker-compose.yml)
# environment:
#   JAVA_OPTS: "-Xmx2g -Xms512m"
```

---

## 7. Mantenimiento del log de ejecuciones n8n

n8n guarda ejecuciones por 7 dias (EXECUTIONS_DATA_MAX_AGE=168).
Si el disco crece mucho, reducir la retencion:

```bash
# En EasyPanel -> n8n -> Environment
# EXECUTIONS_DATA_MAX_AGE=72  # 3 dias
# Reiniciar n8n
docker restart n8n
```

---

## 8. Refrescar la vista materializada manualmente

Si los dashboards muestran datos desactualizados:
```bash
docker exec postgres psql -U sixteam_admin -d ghl_analytics \
  -c "REFRESH MATERIALIZED VIEW CONCURRENTLY mv_unified_attribution;"
```

Esto normalmente corre automatico cada hora via pg_cron. Verificar estado:
```bash
docker exec postgres psql -U sixteam_admin -d ghl_analytics \
  -c "SELECT * FROM cron.job WHERE command LIKE '%mv_unified_attribution%';"
```
