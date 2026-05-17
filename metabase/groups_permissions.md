# Grupos y Permisos en Metabase

Referencia: Platform Spec seccion 8.2

## Los 4 grupos del sistema

| Grupo Metabase | Rol PostgreSQL | Colecciones accesibles | SQL nativo | Puede editar |
|---|---|---|---|---|
| Administradores Sixteam | `sixteam_admin` | Todas | Si - sin restriccion | Si |
| Analistas Sixteam | `sixteam_admin` | Todas | Si - solo lectura | No |
| Cliente [Nombre] | `client_loc_<slug>` | Solo su coleccion | No - solo query builder visual | No |
| Invitados (embed) | `client_loc_<slug>` | Dashboards publicos de su coleccion | No | No |

## Descripcion de cada grupo

### Administradores Sixteam
- Conexion de BD: "Sixteam Admin" (rol `sixteam_admin`, BYPASSRLS)
- Acceso completo a todas las colecciones, preguntas y dashboards
- Pueden crear, editar y eliminar cualquier recurso
- Pueden escribir SQL arbitrario sobre cualquier tabla
- Son los unicos con acceso al panel de administracion de Metabase
- Maximos 3 usuarios en este grupo (solo empleados senior de Sixteam)

### Analistas Sixteam
- Conexion de BD: "Sixteam Admin" (misma conexion que administradores, rol `sixteam_admin`)
- Pueden ver y explorar todos los dashboards sin restriccion de cliente
- Pueden crear preguntas SQL nuevas (read-only sobre BD)
- No pueden editar dashboards existentes ni modificar configuracion del sistema
- No tienen acceso al panel de administracion de Metabase

### Cliente [Nombre]
- Conexion de BD: "Cliente [Nombre]" (rol `client_loc_<slug>`)
- RLS en PostgreSQL garantiza que solo vean filas de su `location_id`
- Solo acceden a su coleccion personal (no ven otros clientes)
- Pueden usar el query builder visual pero NO escribir SQL libre
- No pueden crear nuevas conexiones de BD
- Tipicamente 2-5 usuarios por cliente (gerentes, coordinadores)

### Invitados (embed)
- Conexion de BD: "Cliente [Nombre]" (mismo rol que el grupo Cliente)
- Solo ven dashboards embebidos via JWT en el portal del cliente
- No tienen acceso a la interfaz de Metabase directamente
- Los dashboards embebidos tienen el `location_id` fijado en el token JWT
- No pueden navegar a otras secciones de Metabase

---

## Matriz de permisos detallada

| Accion | Admins Sixteam | Analistas Sixteam | Cliente | Invitados |
|---|---|---|---|---|
| Ver dashboards propios | Si | Si | Si | Si (embed) |
| Ver dashboards otros clientes | Si | Si | No | No |
| Crear dashboard | Si | No | No | No |
| Editar dashboard | Si | No | No | No |
| Eliminar dashboard | Si | No | No | No |
| Escribir SQL nativo | Si | Si | No | No |
| Query builder visual | Si | Si | Si | No |
| Exportar CSV | Si | Si | Si | No |
| Configurar alertas | Si | Si | No | No |
| Administrar usuarios | Si | No | No | No |
| Ver datos todos los clientes | Si | Si | No | No |
| Configurar conexiones BD | Si | No | No | No |

---

## Como crear y configurar los grupos en Metabase UI

### Paso 1: Crear los grupos
1. Ir a **Admin > People > Groups**
2. Hacer clic en **Create a group**
3. Crear los 4 grupos con exactamente estos nombres:
   - `Administradores Sixteam`
   - `Analistas Sixteam`
   - `Cliente [Nombre real del cliente]` (ej: `Cliente Empresa ABC`)
   - `Invitados [Nombre cliente]` (ej: `Invitados Empresa ABC`)

### Paso 2: Configurar permisos de datos por grupo

Ir a **Admin > Permissions > Databases**:

**Para Administradores Sixteam (conexion "Sixteam Admin"):**
- Data access: Unrestricted
- Native query editing: Yes

**Para Analistas Sixteam (conexion "Sixteam Admin"):**
- Data access: Unrestricted
- Native query editing: Yes
- (Restringir edicion de dashboards via colecciones, no via permisos de BD)

**Para Cliente [Nombre] (conexion "Cliente [Nombre]"):**
- Data access: Unrestricted sobre su conexion dedicada
  (RLS en PostgreSQL hace el aislamiento real)
- Native query editing: No

**Para Invitados (embed):**
- No configurar permisos de BD directos; acceden solo via embedding JWT

### Paso 3: Configurar permisos de colecciones

Ir a **Admin > Permissions > Collections**:

| Coleccion | Admins Sixteam | Analistas Sixteam | Cliente [Nombre] | Invitados |
|---|---|---|---|---|
| Our analytics (raiz) | Curate | View | No access | No access |
| Sixteam Internal | Curate | View | No access | No access |
| Clients/ | Curate | View | No access | No access |
| Clients/[Nombre cliente] | Curate | View | Curate | View |

### Paso 4: Agregar usuarios a grupos

Ir a **Admin > People**, editar cada usuario y asignarlo al grupo correspondiente.

Cada usuario solo puede pertenecer a UN grupo (excepto Administradores Sixteam que pueden estar en multiples grupos si es necesario).

### Paso 5: Configurar la conexion de BD por grupo

Para que cada grupo Cliente use su conexion dedicada:
1. Ir a **Admin > Permissions > Databases**
2. Seleccionar la base de datos "Cliente [Nombre]"
3. En el grupo "Cliente [Nombre]", configurar: **Unrestricted**
4. En todos los otros grupos de cliente: **No access** sobre esa conexion

Esto asegura que un cliente del grupo "Cliente ABC" no pueda cambiar a la conexion de "Cliente XYZ".

---

## Notas importantes

- **Nunca exponer** la conexion "Sixteam Admin" (rol `sixteam_admin`) a grupos de cliente.
- El aislamiento real es doble: permisos de coleccion en Metabase + RLS en PostgreSQL.
- Si un dashboard embebido tiene el `location_id` fijado en el JWT, el RLS actua como segunda capa de seguridad aunque el token sea comprometido.
- Revisar permisos despues de cada actualizacion de Metabase (algunas actualizaciones resetean permisos).
