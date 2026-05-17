# Configuracion de Embeddings Firmados (JWT) en Metabase

Los embeddings firmados permiten incrustar dashboards de Metabase en portales de cliente
sin que el cliente necesite una cuenta en Metabase. El `location_id` se fija en el token
JWT para garantizar que el cliente solo vea sus propios datos.

---

## 1. Habilitar embeddings en Metabase

1. Ir a **Admin > Embedding** en Metabase
2. Activar **Embedding in other applications**
3. Copiar el valor de **Embedding secret key** y guardarlo en EasyPanel Secret Manager
   como `MB_EMBEDDING_SECRET_KEY`

---

## 2. Obtener el ID del dashboard a embeber

1. Abrir el dashboard en Metabase
2. Hacer clic en el icono de compartir (flechas) -> **Embed this item in an application**
3. En la configuracion del embed, marcar el parametro `location_id` como **Locked**
   (esto evita que el usuario final lo modifique desde el iframe)
4. Copiar el ID del dashboard de la URL (numero entero, ej: `7`)

---

## 3. Generar el token JWT

### Snippet Node.js

```javascript
// Requiere: npm install jsonwebtoken
const jwt = require('jsonwebtoken');

const METABASE_SITE_URL = process.env.MB_SITE_URL;         // https://analytics.tudominio.com
const METABASE_SECRET_KEY = process.env.MB_EMBEDDING_SECRET_KEY;

/**
 * Genera un token JWT para embeber un dashboard con location_id fijado.
 *
 * @param {number} dashboardId  - ID del dashboard en Metabase
 * @param {string} locationId   - location_id del cliente (fijado = no modificable)
 * @returns {string} URL completa del iframe
 */
function generateEmbedUrl(dashboardId, locationId) {
  const payload = {
    resource: { dashboard: dashboardId },
    params: {
      location_id: locationId   // parametro LOCKED: el usuario no puede cambiarlo
    },
    exp: Math.round(Date.now() / 1000) + (10 * 60)  // expira en 10 minutos
  };

  const token = jwt.sign(payload, METABASE_SECRET_KEY);

  const iframeUrl =
    `${METABASE_SITE_URL}/embed/dashboard/${token}` +
    `#bordered=true&titled=true`;

  return iframeUrl;
}

// Ejemplo de uso en Express.js
app.get('/portal/dashboard', (req, res) => {
  // locationId viene del usuario autenticado en el portal del cliente
  const locationId = req.user.ghl_location_id;
  const url = generateEmbedUrl(7, locationId);  // dashboard ID 7 = Pipeline
  res.json({ embed_url: url });
});
```

### Snippet curl de prueba

```bash
# 1. Generar token manualmente para prueba
# Reemplazar DASHBOARD_ID, LOCATION_ID y SECRET_KEY

DASHBOARD_ID=7
LOCATION_ID="loc_abc123"
SECRET_KEY="tu_mb_embedding_secret_key"

# Generar token con node
TOKEN=$(node -e "
const jwt = require('jsonwebtoken');
const payload = {
  resource: { dashboard: $DASHBOARD_ID },
  params: { location_id: '$LOCATION_ID' },
  exp: Math.round(Date.now()/1000) + 600
};
console.log(jwt.sign(payload, '$SECRET_KEY'));
")

# 2. Verificar que el embed responde 200
curl -I "https://analytics.tudominio.com/embed/dashboard/${TOKEN}"

# Debe devolver HTTP/2 200 con content-type: text/html
```

---

## 4. Configuracion del iframe en el portal de cliente

```html
<!-- Portal del cliente - incluir en la pagina de reportes -->
<iframe
  src="{{ embed_url }}"
  frameborder="0"
  width="100%"
  height="800"
  allowtransparency
></iframe>
```

El `embed_url` es generado por el backend del portal (nunca en el frontend, para no exponer `MB_EMBEDDING_SECRET_KEY`).

---

## 5. Prevencion de leaks de datos

### El parametro `location_id` DEBE ser Locked

En la configuracion del embed en Metabase UI, el parametro `location_id` debe estar marcado como **Locked**, no como **Editable**. Si se marca como Editable, el usuario podria cambiar la URL del iframe para ver datos de otro cliente.

### Expiracion corta del token

El token JWT tiene expiracion de 10 minutos (`exp`). El portal debe solicitar un nuevo token antes de cada carga de pagina. Esto limita la ventana de abuso si un token es interceptado.

### Validacion en el backend del portal

Antes de generar el token, el backend debe validar que el `location_id` solicitado pertenece al usuario autenticado en el portal:

```javascript
// CORRECTO: tomar location_id del usuario autenticado, nunca del request
const locationId = req.user.ghl_location_id;  // del JWT del portal

// INCORRECTO: nunca hacer esto
const locationId = req.query.location_id;  // podria ser manipulado
```

### Double-check via RLS

Aunque el token JWT fije el `location_id`, la conexion de BD del cliente usa el rol
`client_loc_<slug>` que tiene RLS activado. Incluso si el token fuera manipulado para
contener otro `location_id`, la query devolveria 0 resultados porque RLS bloquea el acceso.

---

## 6. Multiples dashboards por cliente

Para cada dashboard (Pipeline, Contactos, CTWA, etc.) se genera una URL distinta con el mismo `location_id` fijado. Ejemplo de tabla de dashboards disponibles:

| Dashboard | ID Metabase | Parametros locked |
|---|---|---|
| Agency Master | 1 | location_id |
| Pipeline | 2 | location_id |
| Contactos | 3 | location_id |
| Conversaciones | 4 | location_id |
| CTWA / Meta Ads | 5 | location_id |
| Citas | 6 | location_id |

Los IDs reales se obtienen despues de recrear los dashboards en la instancia de produccion.

---

## 7. Seguridad adicional - SEC-08 del spec

Para validar que tokens expirados o firmados con key incorrecta son rechazados:

```bash
# Token con key incorrecta - debe dar 400 o redirigir a login
curl -I "https://analytics.tudominio.com/embed/dashboard/token_invalido"

# Token expirado (generar con exp en el pasado)
TOKEN_EXPIRADO=$(node -e "
const jwt = require('jsonwebtoken');
const payload = {
  resource: { dashboard: 1 },
  params: { location_id: 'loc_test' },
  exp: Math.round(Date.now()/1000) - 3600  // expirado hace 1 hora
};
console.log(jwt.sign(payload, 'cualquier_key'));
")
curl -I "https://analytics.tudominio.com/embed/dashboard/${TOKEN_EXPIRADO}"
# Debe devolver 400 o redirigir a pagina de error
```
