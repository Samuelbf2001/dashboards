#!/usr/bin/env bash
# scripts/import_n8n_workflows.sh — Importa todos los workflows JSON a n8n vía REST API
#
# Requisitos:
#   - El stack está levantado y n8n está healthy
#   - .env está cargado (o pasar N8N_URL, N8N_USER, N8N_PASS como env vars)
#
# Uso:
#   bash scripts/import_n8n_workflows.sh
#
# Variables de entorno que lee (con fallback a .env):
#   N8N_URL   — URL base de n8n, p.ej. https://n8n.tudominio.com
#   N8N_USER  — usuario de autenticación básica
#   N8N_PASS  — contraseña de autenticación básica

set -euo pipefail

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()  { echo -e "${RED}[ERR]${NC}  $*"; }
info() { echo -e "${CYAN}[INFO]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
WORKFLOWS_DIR="$SCRIPT_DIR/n8n/workflows"

# Cargar .env si existe y no se pasaron variables explícitamente
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  set -a; source "$ENV_FILE"; set +a
fi

N8N_URL="${N8N_URL:-https://${N8N_HOST:-localhost:5678}}"
N8N_USER="${N8N_USER:-${N8N_BASIC_AUTH_USER:-admin}}"
N8N_PASS="${N8N_PASS:-${N8N_BASIC_AUTH_PASSWORD:-}}"

if [[ -z "$N8N_PASS" ]]; then
  err "N8N_BASIC_AUTH_PASSWORD no configurado en .env ni como variable N8N_PASS"
  exit 1
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  n8n Workflow Import — GHL Analytics Platform"
echo "═══════════════════════════════════════════════════════"
echo ""
info "URL: $N8N_URL"
info "User: $N8N_USER"
echo ""

# ─── Verificar que n8n responde ──────────────────────────────────────────────
info "Verificando conexión a n8n..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -u "${N8N_USER}:${N8N_PASS}" \
  "${N8N_URL}/healthz" 2>/dev/null || echo "000")

if [[ "$HTTP_STATUS" != "200" ]]; then
  err "n8n no responde en ${N8N_URL}/healthz (HTTP $HTTP_STATUS)"
  err "Asegúrate de que el stack está levantado: docker compose up -d"
  exit 1
fi
ok "n8n está accesible."
echo ""

# ─── Obtener API key de n8n (n8n >= 0.198 requiere API key, no basic auth) ──
# n8n < 1.x: usa Basic Auth directamente en la API
# n8n >= 1.x: Basic Auth también funciona en /api/v1 si está habilitado
AUTH_HEADER="Authorization: Basic $(echo -n "${N8N_USER}:${N8N_PASS}" | base64)"

# ─── Importar workflows ───────────────────────────────────────────────────────
IMPORTED=0
SKIPPED=0
FAILED=0

for wf_file in "$WORKFLOWS_DIR"/*.json; do
  wf_name="$(basename "$wf_file")"
  wf_json="$(cat "$wf_file")"

  # Extraer nombre del workflow del JSON
  workflow_name="$(echo "$wf_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('name','unknown'))" 2>/dev/null || echo "unknown")"

  info "Importando: $wf_name ($workflow_name)..."

  # Verificar si ya existe un workflow con este nombre
  EXISTING=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "$AUTH_HEADER" \
    "${N8N_URL}/api/v1/workflows?name=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$workflow_name'))")" 2>/dev/null || echo "000")

  # Intentar crear el workflow
  RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST "${N8N_URL}/api/v1/workflows" \
    -H "$AUTH_HEADER" \
    -H "Content-Type: application/json" \
    -d "$wf_json" 2>/dev/null || echo "")

  HTTP_CODE=$(echo "$RESPONSE" | tail -1)
  BODY=$(echo "$RESPONSE" | head -n -1)

  if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "201" ]]; then
    ok "$workflow_name → importado"
    IMPORTED=$((IMPORTED + 1))
  elif [[ "$HTTP_CODE" == "409" || "$HTTP_CODE" == "400" ]]; then
    # 409 = conflicto (ya existe), intentar actualizar
    WF_ID=$(echo "$BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message','').split('id=')[-1])" 2>/dev/null || echo "")
    warn "$workflow_name → ya existe (omitido). Actualiza manualmente si es necesario."
    SKIPPED=$((SKIPPED + 1))
  else
    err "$workflow_name → FALLÓ (HTTP $HTTP_CODE)"
    FAILED=$((FAILED + 1))
  fi
done

echo ""
echo "───────────────────────────────────────────────────────"
echo "  Resultado del import"
echo "───────────────────────────────────────────────────────"
ok   "Importados: $IMPORTED"
warn "Omitidos (ya existen): $SKIPPED"
[[ $FAILED -gt 0 ]] && err "Fallidos: $FAILED" || true

if [[ $IMPORTED -gt 0 || $SKIPPED -gt 0 ]]; then
  echo ""
  info "Próximos pasos en n8n UI (${N8N_URL}):"
  echo "  1. Ir a Credentials → New → PostgreSQL"
  echo "     Nombre: Postgres n8n_writer"
  echo "     Host: postgres | Port: 5432 | DB: ${POSTGRES_DB:-ghl_analytics}"
  echo "     User: n8n_writer | Pass: <password del rol n8n_writer>"
  echo ""
  echo "  2. Abrir cada workflow y hacer clic en 'Activate'"
  echo "     Los webhooks (WF-01 a WF-06) se activan con el toggle ON"
  echo "     Los scheduled (WF-07 a WF-13) arrancan solos una vez activos"
  echo ""
  echo "  3. Ejecutar manualmente WF-07, WF-08, WF-09 y WF-13 una vez"
  echo "     para la carga histórica inicial de GHL."
fi
echo ""
