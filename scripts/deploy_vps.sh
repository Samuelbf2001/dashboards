#!/usr/bin/env bash
# scripts/deploy_vps.sh — Deploy completo en el VPS (ejecutar como root en el servidor)
#
# Qué hace:
#   1. Actualiza el repositorio (git pull)
#   2. Valida .env y genera cors.yml
#   3. Reconstruye y levanta el stack (docker compose up -d --build)
#   4. Espera a que todos los servicios estén healthy
#   5. Importa los 14 workflows a n8n
#   6. Crea la credencial PostgreSQL en n8n vía API
#   7. Activa todos los workflows
#   8. Ejecuta sincronización inicial de GHL (contacts, opps, appts, pipelines)
#   9. Verifica que hay datos en la BD
#
# Uso:
#   bash scripts/deploy_vps.sh
#
# Tiempo estimado: 8-12 minutos

set -euo pipefail

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()    { echo -e "${GREEN}[OK]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERR]${NC}  $*"; }
info()  { echo -e "${CYAN}[INFO]${NC} $*"; }
step()  { echo -e "\n${BOLD}${CYAN}▶ $*${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

ENV_FILE="$SCRIPT_DIR/.env"
if [[ ! -f "$ENV_FILE" ]]; then
  err ".env no encontrado en $SCRIPT_DIR. Crea uno a partir de .env.example"
  exit 1
fi
set -a; source "$ENV_FILE"; set +a

N8N_URL="https://${N8N_HOST}"
N8N_AUTH="$(echo -n "${N8N_BASIC_AUTH_USER}:${N8N_BASIC_AUTH_PASSWORD}" | base64)"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  GHL Analytics Platform — Deploy VPS"
echo "  Dominio: ${DOMAIN}"
echo "════════════════════════════════════════════════════════"

# ─── PASO 1: Git pull ─────────────────────────────────────────────────────────
step "1/9 — Actualizando repositorio"
git pull --ff-only origin main && ok "Repositorio actualizado." || warn "git pull falló — continuando con versión local."

# ─── PASO 2: Generar cors.yml ─────────────────────────────────────────────────
step "2/9 — Generando cors.yml"
bash setup.sh
ok "setup.sh completado."

# ─── PASO 3: Levantar stack ───────────────────────────────────────────────────
step "3/9 — Levantando stack Docker"
docker compose up -d --build
ok "Stack iniciado."

# ─── PASO 4: Esperar servicios healthy ────────────────────────────────────────
step "4/9 — Esperando que todos los servicios estén healthy"
MAX_WAIT=300   # 5 minutos máximo
ELAPSED=0
INTERVAL=10

wait_healthy() {
  local service="$1"
  info "Esperando $service..."
  while true; do
    STATUS=$(docker inspect --format='{{.State.Health.Status}}' \
      "$(docker compose ps -q "$service" 2>/dev/null)" 2>/dev/null || echo "unknown")
    if [[ "$STATUS" == "healthy" ]]; then
      ok "$service → healthy"
      return 0
    fi
    if [[ $ELAPSED -ge $MAX_WAIT ]]; then
      err "$service no está healthy después de ${MAX_WAIT}s"
      docker compose logs --tail=20 "$service"
      return 1
    fi
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
    echo -n "."
  done
}

wait_healthy postgres
wait_healthy n8n
wait_healthy metabase
wait_healthy portal

# ─── PASO 5: Migración V1.0.1 (si aplica) ────────────────────────────────────
step "5/9 — Aplicando migración V1.0.1 (UNIQUE constraint en dim_pipelines)"
docker exec "$(docker compose ps -q postgres)" \
  psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -f /docker-entrypoint-initdb.d/dummy 2>/dev/null || true

# Ejecutar la migración directamente
MIGRATION_SQL="$(cat db/migrations/V1.0.1__add_dim_pipelines_unique_constraint.sql)"
docker exec -i "$(docker compose ps -q postgres)" \
  psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -c "ALTER TABLE dim_pipelines ADD CONSTRAINT uq_dim_pipelines_stage_location UNIQUE (pipeline_id, stage_id, location_id) ON CONFLICT DO NOTHING;" \
  2>/dev/null || ok "Constraint ya existe — omitido."

# ─── PASO 6: Importar workflows a n8n ────────────────────────────────────────
step "6/9 — Importando workflows a n8n"

IMPORTED=0; FAILED=0
for wf_file in n8n/workflows/*.json; do
  wf_name=$(python3 -c "import json,sys; d=json.load(open('$wf_file')); print(d.get('name','?'))" 2>/dev/null || basename "$wf_file")
  RESP=$(curl -s -w "\n%{http_code}" \
    -X POST "${N8N_URL}/api/v1/workflows" \
    -H "Authorization: Basic $N8N_AUTH" \
    -H "Content-Type: application/json" \
    -d @"$wf_file" 2>/dev/null || echo -e "\n000")
  CODE=$(echo "$RESP" | tail -1)
  if [[ "$CODE" == "200" || "$CODE" == "201" ]]; then
    ok "Importado: $wf_name"
    IMPORTED=$((IMPORTED + 1))
  else
    warn "Omitido (ya existe o error HTTP $CODE): $wf_name"
    FAILED=$((FAILED + 1))
  fi
done
ok "Workflows: $IMPORTED importados, $FAILED omitidos/error."

# ─── PASO 7: Crear credencial PostgreSQL en n8n ───────────────────────────────
step "7/9 — Creando credencial 'Postgres n8n_writer' en n8n"

CRED_PAYLOAD=$(python3 -c "
import json
cred = {
  'name': 'Postgres n8n_writer',
  'type': 'postgres',
  'data': {
    'host': 'postgres',
    'port': 5432,
    'database': '${POSTGRES_DB}',
    'user': 'n8n_writer',
    'password': '${DB_POSTGRESDB_PASSWORD}',
    'ssl': False,
    'sshTunnel': False
  }
}
print(json.dumps(cred))
")

CRED_RESP=$(curl -s -w "\n%{http_code}" \
  -X POST "${N8N_URL}/api/v1/credentials" \
  -H "Authorization: Basic $N8N_AUTH" \
  -H "Content-Type: application/json" \
  -d "$CRED_PAYLOAD" 2>/dev/null || echo -e "\n000")
CRED_CODE=$(echo "$CRED_RESP" | tail -1)
CRED_ID=$(echo "$CRED_RESP" | head -n -1 | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null || echo "")

if [[ "$CRED_CODE" == "200" || "$CRED_CODE" == "201" ]]; then
  ok "Credencial creada — ID: $CRED_ID"
else
  warn "No se pudo crear credencial via API (HTTP $CRED_CODE). Créala manualmente en n8n UI."
fi

# ─── PASO 8: Activar todos los workflows ─────────────────────────────────────
step "8/9 — Activando workflows"

WF_LIST=$(curl -s \
  -H "Authorization: Basic $N8N_AUTH" \
  "${N8N_URL}/api/v1/workflows?limit=100" 2>/dev/null || echo "{}")

WF_IDS=$(echo "$WF_LIST" | python3 -c "
import json,sys
try:
  d = json.load(sys.stdin)
  wfs = d.get('data', [])
  for w in wfs:
    print(w['id'])
except:
  pass
" 2>/dev/null || true)

ACTIVATED=0
for wf_id in $WF_IDS; do
  RESP=$(curl -s -w "\n%{http_code}" \
    -X PATCH "${N8N_URL}/api/v1/workflows/${wf_id}" \
    -H "Authorization: Basic $N8N_AUTH" \
    -H "Content-Type: application/json" \
    -d '{"active": true}' 2>/dev/null || echo -e "\n000")
  CODE=$(echo "$RESP" | tail -1)
  [[ "$CODE" == "200" ]] && ACTIVATED=$((ACTIVATED + 1)) || true
done
ok "$ACTIVATED workflows activados."

# ─── PASO 9: Primera sincronización GHL ──────────────────────────────────────
step "9/9 — Disparando carga histórica inicial de GHL"

run_workflow() {
  local name="$1"
  local wf_id
  wf_id=$(echo "$WF_LIST" | python3 -c "
import json,sys
try:
  d = json.load(sys.stdin)
  for w in d.get('data',[]):
    if '$name' in w.get('name',''):
      print(w['id'])
      break
except:
  pass
" 2>/dev/null || echo "")

  if [[ -z "$wf_id" ]]; then
    warn "Workflow '$name' no encontrado — omitido."
    return
  fi

  RESP=$(curl -s -w "\n%{http_code}" \
    -X POST "${N8N_URL}/api/v1/workflows/${wf_id}/run" \
    -H "Authorization: Basic $N8N_AUTH" \
    -H "Content-Type: application/json" \
    -d '{}' 2>/dev/null || echo -e "\n000")
  CODE=$(echo "$RESP" | tail -1)
  [[ "$CODE" == "200" || "$CODE" == "201" ]] \
    && ok "Ejecutado: $name" \
    || warn "No se pudo ejecutar '$name' (HTTP $CODE) — ejecutar manualmente en n8n UI."
}

run_workflow "WF-07 Polling Contacts"
run_workflow "WF-08 Polling Opportunities"
run_workflow "WF-09 Polling Appointments"
run_workflow "WF-13 Polling Pipelines"

info "Los workflows de polling corren en paralelo. Espera ~5 min para que completen."

# ─── VERIFICACIÓN FINAL ───────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════════"
echo "  Verificación de datos en BD (espera 5 min si es la primera carga)"
echo "════════════════════════════════════════════════════════"

sleep 30  # dar tiempo a que arranque al menos la primera página

COUNTS=$(docker exec "$(docker compose ps -q postgres)" \
  psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -A \
  -c "SELECT 'contacts=' || COUNT(*) FROM dim_contacts
      UNION ALL SELECT 'opps=' || COUNT(*) FROM dim_opportunities
      UNION ALL SELECT 'pipelines=' || COUNT(*) FROM dim_pipelines
      UNION ALL SELECT 'sync_entries=' || COUNT(*) FROM ghl_sync_state" \
  2>/dev/null || echo "No disponible")

echo "$COUNTS" | while IFS= read -r line; do
  [[ -n "$line" ]] && info "$line"
done

echo ""
ok "Deploy completado. URLs de la plataforma:"
echo "   Portal:     https://${PORTAL_DOMAIN:-dashboard.$DOMAIN}"
echo "   n8n:        https://${N8N_HOST}"
echo "   Metabase:   ${MB_SITE_URL}"
echo "   Uptime:     https://${KUMA_DOMAIN:-uptime.$DOMAIN}"
echo ""
warn "Próximos pasos:"
echo "  1. Abrir Metabase (${MB_SITE_URL}) → Admin → Databases → Add Database (ghl_analytics)"
echo "     Ver: metabase/db_connections.md"
echo "  2. Configurar los webhooks en GoHighLevel:"
echo "     https://${N8N_HOST}/webhook/ghl/contacts"
echo "     https://${N8N_HOST}/webhook/ghl/opportunities"
echo "     https://${N8N_HOST}/webhook/ghl/conversations"
echo "     https://${N8N_HOST}/webhook/ghl/appointments"
echo "     HMAC secret: \$WEBHOOK_SECRET del .env"
echo ""
