#!/usr/bin/env bash
# setup.sh — Preparación pre-deploy para GHL Analytics Platform
#
# Ejecutar UNA VEZ antes de 'docker compose up -d':
#   bash setup.sh
#
# Qué hace:
#   1. Valida que .env existe y tiene todas las variables requeridas
#   2. Genera infra/traefik/dynamic/cors.yml con los dominios reales
#      (Traefik no interpola env vars en archivos de configuración dinámica)
#   3. Imprime un checklist de pasos manuales que quedan pendientes
#
# Dependencias: bash, envsubst (parte de gettext-base / gettext en Alpine/Debian)

set -euo pipefail

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()  { echo -e "${RED}[ERR]${NC}  $*"; }
info() { echo -e "${CYAN}[INFO]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
CORS_TPL="$SCRIPT_DIR/infra/traefik/dynamic/cors.yml.tpl"
CORS_OUT="$SCRIPT_DIR/infra/traefik/dynamic/cors.yml"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  GHL Analytics Platform — Setup Pre-Deploy"
echo "═══════════════════════════════════════════════════════"
echo ""

# ─── PASO 1: Verificar .env ───────────────────────────────────────────────────
info "Verificando .env ..."

if [[ ! -f "$ENV_FILE" ]]; then
  err ".env no encontrado. Ejecuta: cp .env.example .env  y luego edita los valores."
  exit 1
fi

# shellcheck source=/dev/null
set -a; source "$ENV_FILE"; set +a

ERRORS=0

check_var() {
  local var="$1"; local val="${!var:-}"
  if [[ -z "$val" || "$val" == *"CAMBIAR_POR"* || "$val" == *"tudominio"* ]]; then
    err "Variable faltante o sin editar: $var"
    ERRORS=$((ERRORS + 1))
  else
    ok "$var"
  fi
}

# Variables obligatorias para que el stack arranque
REQUIRED_VARS=(
  DOMAIN
  LETSENCRYPT_EMAIL
  POSTGRES_PASSWORD
  POSTGRES_USER
  POSTGRES_DB
  N8N_BASIC_AUTH_USER
  N8N_BASIC_AUTH_PASSWORD
  N8N_HOST
  WEBHOOK_URL
  N8N_ENCRYPTION_KEY
  GHL_API_KEY
  GHL_LOCATION_IDS
  WEBHOOK_SECRET
  DB_POSTGRESDB_USER
  DB_POSTGRESDB_PASSWORD
  MB_DB_USER
  MB_DB_PASS
  MB_SITE_URL
  MB_EMBEDDING_SECRET_KEY
  PORTAL_ADMIN_USER
  PORTAL_ADMIN_PASSWORD
)

for v in "${REQUIRED_VARS[@]}"; do check_var "$v"; done

if [[ $ERRORS -gt 0 ]]; then
  echo ""
  err "$ERRORS variable(s) sin configurar en .env. Corrígelas y vuelve a ejecutar."
  exit 1
fi

ok "Todas las variables requeridas están presentes."

# ─── PASO 2: Generar cors.yml ─────────────────────────────────────────────────
echo ""
info "Generando infra/traefik/dynamic/cors.yml ..."

if [[ ! -f "$CORS_TPL" ]]; then
  err "Template no encontrado: $CORS_TPL"
  exit 1
fi

if ! command -v envsubst &>/dev/null; then
  warn "envsubst no está instalado. Instalando (requiere apt/apk)..."
  if command -v apt-get &>/dev/null; then
    apt-get install -y --no-install-recommends gettext-base
  elif command -v apk &>/dev/null; then
    apk add --no-cache gettext
  else
    err "No se pudo instalar envsubst. Instálalo manualmente: apt-get install gettext-base"
    exit 1
  fi
fi

# Solo sustituir la variable DOMAIN en el template
DOMAIN="${DOMAIN}" envsubst '${DOMAIN}' < "$CORS_TPL" > "$CORS_OUT"
ok "cors.yml generado → $CORS_OUT"

# Verificar resultado
if grep -q '${DOMAIN}' "$CORS_OUT"; then
  err "cors.yml todavía tiene placeholders sin sustituir. Revisa el template."
  exit 1
fi

# ─── PASO 3: Checklist de pasos manuales ──────────────────────────────────────
echo ""
echo "───────────────────────────────────────────────────────"
echo "  Checklist — Pasos manuales antes del primer deploy"
echo "───────────────────────────────────────────────────────"
echo ""
warn "Los siguientes pasos requieren acción manual:"
echo ""
echo "  [ ] 1. Levantar el stack:"
echo "         docker compose up -d"
echo ""
echo "  [ ] 2. Verificar que los 5 contenedores están healthy:"
echo "         docker ps --format 'table {{.Names}}\t{{.Status}}'"
echo ""
echo "  [ ] 3. Importar workflows de n8n (con el stack levantado):"
echo "         bash scripts/import_n8n_workflows.sh"
echo "         (URL: https://${N8N_HOST}  |  User: ${N8N_BASIC_AUTH_USER})"
echo ""
echo "  [ ] 4. En n8n UI → Credentials → New Credential → PostgreSQL:"
echo "         Name: Postgres n8n_writer"
echo "         Host: postgres  |  Port: 5432"
echo "         Database: ${POSTGRES_DB}"
echo "         User: n8n_writer  |  Password: <password del rol n8n_writer>"
echo ""
echo "  [ ] 5. En Metabase UI → Admin → Databases → Add Database:"
echo "         Engine: PostgreSQL"
echo "         Host: postgres  |  Port: 5432"
echo "         Database: ${POSTGRES_DB}"
echo "         Ver: metabase/db_connections.md"
echo ""
echo "  [ ] 6. Si el stack ya estaba desplegado, ejecutar migración:"
echo "         psql -h localhost -U ${POSTGRES_USER} -d ${POSTGRES_DB} \\"
echo "           -f db/migrations/V1.0.1__add_dim_pipelines_unique_constraint.sql"
echo ""
echo "  [ ] 7. Configurar GHL Webhooks en GoHighLevel:"
echo "         URL base: ${WEBHOOK_URL}ghl/"
echo "         → Contacts:       ${WEBHOOK_URL}ghl/contacts"
echo "         → Opportunities:  ${WEBHOOK_URL}ghl/opportunities"
echo "         → Conversations:  ${WEBHOOK_URL}ghl/conversations"
echo "         → Appointments:   ${WEBHOOK_URL}ghl/appointments"
echo "         Secret (HMAC):    ${WEBHOOK_SECRET:0:6}... (ver .env WEBHOOK_SECRET)"
echo ""
echo ""
ok "setup.sh completado. Continúa con el checklist de arriba."
echo ""
