# Conexiones de Base de Datos en Metabase

Metabase se conecta a PostgreSQL con conexiones dedicadas por tipo de acceso.
Nunca se usa la misma conexion para administradores y clientes.

---

## Conexiones requeridas

### Conexion 1: "Sixteam Admin"

Usada exclusivamente por los grupos **Administradores Sixteam** y **Analistas Sixteam**.

| Campo | Valor |
|---|---|
| Nombre de la conexion | `Sixteam Admin` |
| Tipo de BD | PostgreSQL |
| Host | `postgres` (nombre del contenedor Docker) |
| Puerto | `5432` |
| Nombre de BD | `ghl_analytics` |
| Usuario | `sixteam_admin` |
| Contrasena | `[SECRETO - de EasyPanel Secret Manager]` |
| SSL | Deshabilitado (red interna Docker) |
| Tunnel SSH | No |
| Readonly | Si (recomendado) |
| BYPASSRLS | Si (el rol sixteam_admin tiene BYPASSRLS) |

**Visibilidad:** Solo accesible desde los grupos "Administradores Sixteam" y "Analistas Sixteam".
Nunca asignar esta conexion a grupos de cliente.

### Conexion 2: "Cliente [Nombre del cliente]" (una por cliente)

Una conexion independiente por cada cliente de Sixteam. RLS en PostgreSQL
garantiza que este rol solo vea filas de su `location_id`.

| Campo | Valor |
|---|---|
| Nombre de la conexion | `Cliente [Nombre]` (ej: `Cliente Empresa ABC`) |
| Tipo de BD | PostgreSQL |
| Host | `postgres` |
| Puerto | `5432` |
| Nombre de BD | `ghl_analytics` |
| Usuario | `client_loc_<slug>` (ej: `client_loc_abc123`) |
| Contrasena | `[SECRETO - generada en el onboarding del cliente]` |
| SSL | Deshabilitado (red interna Docker) |
| Tunnel SSH | No |
| Readonly | Si |
| BYPASSRLS | No (RLS activo para este rol) |

**Visibilidad:** Solo accesible desde el grupo "Cliente [Nombre]" correspondiente.
Ver seccion "Asignar conexion al grupo" a continuacion.

---

## Como registrar una nueva conexion en Metabase UI

1. Ir a **Admin > Databases > Add database**
2. Seleccionar **PostgreSQL**
3. Completar los campos segun la tabla de arriba
4. Hacer clic en **Save** y esperar a que la conexion se valide (icono verde)
5. Si falla, verificar:
   - Que el contenedor `postgres` este corriendo: `docker ps | grep postgres`
   - Que el rol exista: `psql -U sixteam_admin -c "\du client_loc_abc123"`
   - Que la contrasena sea correcta
   - Que el rol tenga permisos SELECT sobre las tablas: `\dp dim_contacts`

---

## Asignar conexion al grupo del cliente

Despues de crear la conexion, restringir su visibilidad:

1. Ir a **Admin > Permissions > Databases**
2. Seleccionar la conexion recien creada "Cliente [Nombre]"
3. Configurar permisos por grupo:
   - **Administradores Sixteam**: No access (usan su propia conexion)
   - **Analistas Sixteam**: No access (usan su propia conexion)
   - **Cliente [Nombre]**: Unrestricted
   - **Todos los otros grupos**: No access

Esto garantiza que el grupo "Cliente ABC" no pueda ver la conexion de "Cliente XYZ".

---

## Verificacion de aislamiento

Para verificar que el rol del cliente solo ve sus datos:

```sql
-- Conectar como el rol del cliente
\c ghl_analytics client_loc_abc123

-- Intentar leer datos de otro cliente - debe devolver 0 filas
SELECT COUNT(*) FROM dim_contacts WHERE location_id = 'otro_location_id';
-- Resultado esperado: 0

-- Ver sus propios datos
SELECT COUNT(*) FROM dim_contacts;
-- Resultado esperado: N filas (solo de su location_id)
```

---

## Notas de seguridad

- La contrasena del rol `client_loc_<slug>` se genera aleatoriamente en el onboarding
  y se almacena en EasyPanel Secret Manager como `CLIENT_LOC_<SLUG>_PASSWORD`.
- Nunca compartir la contrasena del rol con el cliente; el cliente solo accede via
  Metabase (usuario/contrasena de Metabase, no de PostgreSQL).
- Si un cliente se da de baja, ejecutar:
  ```sql
  REVOKE ALL ON ALL TABLES IN SCHEMA public FROM client_loc_<slug>;
  DROP ROLE client_loc_<slug>;
  ```
  Y eliminar la conexion en Metabase y el grupo correspondiente.
- Las conexiones de BD se almacenan encriptadas en `metabase_app` (BD interna de Metabase)
  usando `MB_ENCRYPTION_KEY`. No manipular directamente esa BD.
