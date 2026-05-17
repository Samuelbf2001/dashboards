# Client Onboarding - GHL Analytics Platform

Proceso paso a paso para agregar un nuevo cliente de Sixteam a la plataforma.
Tiempo estimado: 45-90 minutos.

---

## Informacion requerida antes de comenzar

Solicitar al cliente o account manager:

- [ ] GHL Location ID (de GHL -> Settings -> Business Profile -> Location ID)
- [ ] Nombre del cliente para la conexion en Metabase
- [ ] Email(s) del cliente que tendran acceso a los dashboards
- [ ] Si usa anuncios CTWA de Meta: acceso al App Dashboard de Meta
- [ ] Si usa Mailgun/SendGrid: API key del ESP

Convencion de nombre: usar un `slug` corto y sin espacios.
Ejemplo: cliente "Empresa ABC" -> slug `empresa_abc` -> location_id en GHL `loc_abc_xyz123`

---

## Paso 1: Crear rol PostgreSQL del cliente

```bash
# Reemplazar SLUG y LOCATION_ID con los valores reales
SLUG="empresa_abc"
LOCATION_ID="loc_abc_xyz123"
CLIENT_PASS=$(openssl rand -base64 24)

# Guardar la contrasena en EasyPanel Secret Manager como:
# CLIENT_LOC_EMPRESA_ABC_PASSWORD = ${CLIENT_PASS}

docker exec postgres psql -U sixteam_admin -d ghl_analytics -c "
-- Crear rol
CREATE ROLE client_loc_${SLUG} LOGIN PASSWORD '${CLIENT_PASS}';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO client_loc_${SLUG};

-- Politicas RLS para las 9 tablas
CREATE POLICY rls_contacts_${SLUG} ON dim_contacts
  FOR ALL TO client_loc_${SLUG} USING (location_id = '${LOCATION_ID}');

CREATE POLICY rls_opps_${SLUG} ON dim_opportunities
  FOR ALL TO client_loc_${SLUG} USING (location_id = '${LOCATION_ID}');

CREATE POLICY rls_conv_${SLUG} ON dim_conversations
  FOR ALL TO client_loc_${SLUG} USING (location_id = '${LOCATION_ID}');

CREATE POLICY rls_pipelines_${SLUG} ON dim_pipelines
  FOR ALL TO client_loc_${SLUG} USING (location_id = '${LOCATION_ID}');

CREATE POLICY rls_ads_${SLUG} ON dim_ads
  FOR ALL TO client_loc_${SLUG} USING (location_id = '${LOCATION_ID}');

CREATE POLICY rls_messages_${SLUG} ON fact_messages
  FOR ALL TO client_loc_${SLUG} USING (location_id = '${LOCATION_ID}');

CREATE POLICY rls_opp_hist_${SLUG} ON fact_opp_stage_history
  FOR ALL TO client_loc_${SLUG} USING (location_id = '${LOCATION_ID}');

CREATE POLICY rls_email_evt_${SLUG} ON fact_email_events
  FOR ALL TO client_loc_${SLUG} USING (location_id = '${LOCATION_ID}');

CREATE POLICY rls_ctwa_${SLUG} ON fact_ctwa_clicks
  FOR ALL TO client_loc_${SLUG} USING (location_id = '${LOCATION_ID}');
"
```

Alternativamente, usar el template parametrizable:
```bash
# Reemplazar los marcadores en el template
sed "s/{{SLUG}}/${SLUG}/g; s/{{LOCATION_ID}}/${LOCATION_ID}/g; s/{{PASSWORD}}/${CLIENT_PASS}/g" \
  db/seed/client_provision_template.sql \
  | docker exec -i postgres psql -U sixteam_admin -d ghl_analytics
```

### Verificar el aislamiento RLS
```bash
docker exec postgres psql -U "client_loc_${SLUG}" -d ghl_analytics \
  -W -c "SELECT COUNT(*) FROM dim_contacts;"
# Debe devolver solo las filas del cliente (o 0 si aun no hay datos)

# Verificar que NO ve datos de otro cliente
docker exec postgres psql -U "client_loc_${SLUG}" -d ghl_analytics \
  -W -c "SELECT COUNT(*) FROM dim_contacts WHERE location_id = 'otro_location_id';"
# Debe devolver 0
```

---

## Paso 2: Crear conexion de BD en Metabase

1. Ir a Admin -> Databases -> Add database -> PostgreSQL
2. Completar:
   - Name: `Cliente Empresa ABC`
   - Host: `postgres`
   - Port: `5432`
   - Database: `ghl_analytics`
   - Username: `client_loc_empresa_abc`
   - Password: `${CLIENT_PASS}` (de Secret Manager)
3. Click Save y verificar conexion verde

---

## Paso 3: Crear grupo y usuarios en Metabase

1. Admin -> People -> Groups -> Create group: `Cliente Empresa ABC`
2. Admin -> Permissions -> Databases:
   - Conexion "Cliente Empresa ABC" -> grupo "Cliente Empresa ABC": `Unrestricted`
   - Todos los demas grupos: `No access` sobre esta conexion
3. Admin -> People -> Invite user:
   - Email del cliente
   - Agregar al grupo "Cliente Empresa ABC"
4. El cliente recibe email de bienvenida con link para crear contrasena

---

## Paso 4: Crear coleccion y duplicar dashboards

1. Admin -> Collections -> New collection: `Clients/Empresa ABC`
2. Admin -> Permissions -> Collections:
   - `Clients/Empresa ABC` -> grupo "Cliente Empresa ABC": `Curate`
3. Ir a la coleccion template de Sixteam
4. Para cada uno de los 6 dashboards:
   - Abrir dashboard -> botones -> Duplicate
   - Mover la copia a `Clients/Empresa ABC`
   - Editar cada card para usar la conexion "Cliente Empresa ABC"

Nota: Al usar la conexion dedicada del cliente, RLS filtra automaticamente.
No se necesita agregar `WHERE location_id = '...'` en los SQL.

---

## Paso 5: Configurar webhooks en GHL Sub-account

En GHL: Sub-account del cliente -> Settings -> Integrations -> Webhooks -> Add Webhook

| Evento | URL |
|---|---|
| Contact Create | `https://n8n.tudominio.com/ghl/contacts` |
| Contact Update | `https://n8n.tudominio.com/ghl/contacts` |
| Opportunity Create | `https://n8n.tudominio.com/ghl/opportunities` |
| Opportunity Status Update | `https://n8n.tudominio.com/ghl/opportunities` |
| Conversation Update | `https://n8n.tudominio.com/ghl/conversations` |
| Appointment Create | `https://n8n.tudominio.com/ghl/appointments` |
| Appointment Update | `https://n8n.tudominio.com/ghl/appointments` |

En cada webhook:
- Secret: valor de `WEBHOOK_SECRET`

---

## Paso 6: Configurar Meta Cloud API (solo si usa CTWA)

Requisito: el cliente tiene WhatsApp Business conectado via Meta Cloud API en GHL.

1. En Meta for Developers -> App del cliente -> WhatsApp -> Configuration
2. Callback URL: `https://n8n.tudominio.com/meta/ctwa`
3. Verify token: valor de `META_VERIFY_TOKEN`
4. Click "Verify and save"
5. Suscribirse a: `messages`
6. Verificar que WF-06 responde el challenge:
   ```bash
   curl "https://n8n.tudominio.com/meta/ctwa?hub.mode=subscribe&hub.verify_token=${META_VERIFY_TOKEN}&hub.challenge=test123"
   # Debe responder: test123
   ```

---

## Paso 7: Validar primer flujo end-to-end

### Test manual rapido
1. Crear un contacto de prueba en GHL (Sub-account del cliente)
2. Esperar 10-15 segundos
3. Verificar en PostgreSQL:
   ```bash
   docker exec postgres psql -U sixteam_admin -d ghl_analytics \
     -c "SELECT contact_id, email, location_id FROM dim_contacts
         WHERE location_id = '${LOCATION_ID}'
         ORDER BY synced_at DESC LIMIT 5;"
   ```
4. Si aparece el contacto: flujo de webhooks funcionando

### Verificar en Metabase
1. Login como el usuario del cliente
2. Abrir el dashboard de Contactos de su coleccion
3. El contador de "Total contactos" debe mostrar > 0

### Correr tests de ETL para el nuevo cliente
```bash
TEST_LOCATION_ID="${LOCATION_ID}" bash tests/etl/etl_01_webhook_upsert.sh
TEST_LOCATION_ID="${LOCATION_ID}" bash tests/etl/etl_03_no_duplicates.sh
```

---

## Checklist de onboarding completado

- [ ] Rol PostgreSQL `client_loc_${SLUG}` creado
- [ ] 9 politicas RLS aplicadas
- [ ] RLS verificado: cliente no ve datos de otro (SEC-01 pasado)
- [ ] Conexion Metabase "Cliente ${NAME}" creada y verificada
- [ ] Grupo Metabase creado con permisos correctos
- [ ] Usuario(s) cliente invitados y asignados al grupo
- [ ] Coleccion `Clients/${NAME}` creada con permisos
- [ ] 6 dashboards duplicados a la coleccion del cliente
- [ ] Webhooks GHL configurados para todos los eventos
- [ ] Meta Cloud API configurada (si aplica)
- [ ] Primer contacto de prueba sincronizado y visible en Metabase
- [ ] Credenciales documentadas en el Secret Manager de EasyPanel
