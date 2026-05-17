# Troubleshooting - GHL Analytics Platform

Guia de diagnostico para sintomas comunes.

---

## "No llegan datos" / Dashboard vacio

### Diagnostico paso a paso

**1. Verificar que los containers estan corriendo:**
```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
# Todos deben estar "Up"
```

**2. Verificar webhooks en GHL:**
- GHL Sub-account -> Settings -> Integrations -> Webhooks -> Event Log
- Buscar errores recientes. Si hay, verificar que la URL y el secret esten correctos.

**3. Verificar que n8n recibe los webhooks:**
```bash
docker logs n8n --tail 50 | grep -i "webhook\|contact\|error"
```
En n8n UI: Executions -> ver si hay ejecuciones recientes de WF-01.

**4. Verificar que la BD tiene datos:**
```bash
docker exec postgres psql -U sixteam_admin -d ghl_analytics \
  -c "SELECT COUNT(*) FROM dim_contacts;"
```

**5. Verificar que la vista materializada no esta desactualizada:**
```bash
# Ver cuando fue el ultimo refresh
docker exec postgres psql -U sixteam_admin -d ghl_analytics \
  -c "SELECT schemaname, matviewname, ispopulated FROM pg_matviews;"

# Refrescar manualmente si es necesario
docker exec postgres psql -U sixteam_admin -d ghl_analytics \
  -c "REFRESH MATERIALIZED VIEW CONCURRENTLY mv_unified_attribution;"
```

**Solucion:** Si los datos estan en dim_contacts pero no en el dashboard, refrescar la MV.
Si no hay datos en dim_contacts, revisar los webhooks o correr el polling manualmente.

---

## "Dashboard vacio" pero hay datos en PostgreSQL

### Diagnostico

**1. Verificar que Metabase usa la conexion correcta:**
- Admin -> Databases -> verificar que la conexion "Sixteam Admin" esta activa

**2. Verificar que el card apunta a la tabla correcta:**
- Abrir el card en modo edicion
- Verificar que la query SQL referencia `mv_unified_attribution` o las tablas correctas

**3. Verificar filtros activos:**
- Revisar si hay filtros de fecha que esten excluyendo todos los datos
- Cambiar el rango de fechas a "All time"

**4. Ejecutar la query directamente en PostgreSQL:**
```bash
docker exec postgres psql -U sixteam_admin -d ghl_analytics \
  -c "SELECT COUNT(*) FROM mv_unified_attribution;"
# Si devuelve 0: la MV esta vacia. Refrescar.
```

---

## "Cliente ve datos de otro cliente" (RLS fallido)

**CRITICO: Responder inmediatamente.**

### Diagnostico

**1. Verificar que RLS esta habilitado en la tabla:**
```bash
docker exec postgres psql -U sixteam_admin -d ghl_analytics \
  -c "SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname='public';"
# rowsecurity debe ser TRUE para todas las tablas de analytics
```

**2. Verificar que existe la policy del cliente:**
```bash
docker exec postgres psql -U sixteam_admin -d ghl_analytics \
  -c "\dp dim_contacts"
# Debe mostrar la policy del cliente
```

**3. Verificar que la conexion de Metabase del cliente usa el rol correcto:**
- Admin -> Databases -> "Cliente [Nombre]" -> Edit
- Username debe ser `client_loc_<slug>`, NO `sixteam_admin`

**4. Probar el aislamiento directamente:**
```bash
docker exec postgres psql -U "client_loc_slug_del_cliente" \
  -d ghl_analytics -W \
  -c "SELECT DISTINCT location_id FROM dim_contacts;"
# Solo debe aparecer el location_id del cliente
```

**Solucion:** Si la policy no existe, ejecutar las sentencias RLS del `CLIENT_ONBOARDING.md`.
Si la conexion usa el rol incorrecto, corregir en Admin -> Databases.

---

## "Polling no avanza" (datos desactualizados en BD)

### Diagnostico

**1. Verificar el cursor en ghl_sync_state:**
```bash
docker exec postgres psql -U sixteam_admin -d ghl_analytics \
  -c "SELECT entity, location_id, last_synced_at, last_error, updated_at
      FROM ghl_sync_state
      ORDER BY updated_at DESC;"
```

- Si `last_error` no es NULL: hay un error en el polling. Revisar n8n logs.
- Si `last_synced_at` es muy viejo: WF-07 no esta corriendo.

**2. Verificar que los workflows de polling estan activos:**
- n8n UI -> Workflows -> WF-07, WF-08, WF-09
- Deben estar en estado "Active"

**3. Verificar credenciales de la GHL API:**
```bash
# Probar la API de GHL manualmente
curl -H "Authorization: Bearer ${GHL_API_KEY}" \
  "https://services.leadconnectorhq.com/contacts/?locationId=LOCATION_ID&limit=1"
# Debe devolver JSON con contactos
```

**Solucion:** Si el cursor esta en NULL, el workflow nunca corrio. Activar WF-07 y esperar.
Si hay error de autenticacion con GHL, renovar GHL_API_KEY en EasyPanel.

---

## "Embedding tarda mucho" / timeout en iframe

### Diagnostico

**1. Medir tiempo de respuesta del dashboard:**
```bash
time curl -s "https://analytics.tudominio.com/embed/dashboard/TOKEN" > /dev/null
```

**2. Verificar RAM del sistema:**
```bash
docker stats --no-stream | awk '{print $2, $4}'
# Metabase consume mas RAM = dashboards mas lentos
```

**3. Verificar que la MV esta actualizada:**
- Si mv_unified_attribution no tiene indices, las queries seran lentas
```bash
docker exec postgres psql -U sixteam_admin -d ghl_analytics \
  -c "\d mv_unified_attribution"
```

**Solucion:**
- Aumentar RAM del VPS si Metabase esta usando >2GB
- Asegurar que los indices sobre la MV existen (idx_mv_location, idx_mv_opp_status, etc.)
- Usar filtros en el dashboard para reducir el volumen de datos consultados

---

## "CAPI rechaza eventos" (Meta Conversions API)

### Diagnostico

**1. Verificar logs de WF-11 (CTWA Enricher):**
- n8n UI -> WF-11 -> ultima ejecucion
- Buscar el nodo "Send CAPI event" y ver el error

**2. Verificar el token de Meta:**
```bash
# Probar el token manualmente
curl -X POST \
  "https://graph.facebook.com/v18.0/PIXEL_ID/events?access_token=META_CLOUD_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"data":[{"event_name":"test_event","event_time":1729000000,"action_source":"website"}],"test_event_code":"TEST12345"}'
```

**3. Verificar que ctwa_clid no este vencido:**
- Meta rechaza eventos CAPI con ctwa_clid de mas de 7 dias

**Solucion:** Renovar META_CLOUD_API_TOKEN en EasyPanel. Los ctwa_clid vencidos no pueden
enviarse retroactivamente a CAPI - es una limitacion de Meta.

---

## "Backup fallo"

### Diagnostico
```bash
# Ver si el ultimo backup existe
ls -lh /var/backups/postgres/ | tail -5

# Ver el log del cron de backup
docker exec postgres cat /var/log/pg_backup.log 2>/dev/null || \
  docker logs postgres | grep -i "backup\|dump" | tail -10
```

### Forzar backup manual
```bash
BACKUP_FILE="/var/backups/postgres/ghl_analytics_manual_$(date +%Y%m%d_%H%M%S).dump"

docker exec postgres pg_dump \
  -U sixteam_admin \
  -d ghl_analytics \
  -Fc \
  -f "/tmp/backup_manual.dump"

docker cp "postgres:/tmp/backup_manual.dump" "${BACKUP_FILE}"
ls -lh "${BACKUP_FILE}"
```

**Solucion:** Si falta espacio en disco (`df -h` muestra >90%), liberar espacio eliminando
backups viejos (conservar minimo los ultimos 7):
```bash
ls -t /var/backups/postgres/*.dump | tail -n +8 | xargs rm -f
```

---

## "n8n no procesa - workflow se cayo"

### Reiniciar n8n
```bash
docker restart n8n
# Esperar 30s
docker logs n8n --tail 20
```

### Si los workflows quedaron inactivos tras el reinicio
n8n reautomaticamente reactiva workflows marcados como "Active" al reiniciar.
Verificar en UI que todos los workflows esten en verde.

---

## Contactos de escalada

| Problema | Escalar a |
|---|---|
| RLS fallido (datos cruzados) | CTO Sixteam inmediatamente |
| Perdida de datos en BD | CTO Sixteam + restaurar desde backup |
| Certificados SSL vencidos | DevOps (renovar via Traefik + Let's Encrypt) |
| VPS no responde | Soporte Hostinger |
| GHL API devuelve 401 | Account manager del cliente + GHL Support |
