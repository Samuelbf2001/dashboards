#!/usr/bin/env bash
# SEC-09 [BLOQUEANTE] - n8n UI no accesible sin autenticacion
# Criterio: GET a n8n UI sin credenciales retorna 401
# Exit 0 = PASS, 1 = FAIL

set -euo pipefail

: "${N8N_HOST:?Requerida: N8N_HOST}"

N8N_URL="https://${N8N_HOST}"

echo "=== SEC-09: n8n authentication required ==="
echo "  URL: ${N8N_URL}"

# Intentar acceder sin credenciales
response=$(curl -s -o /tmp/sec09_body.txt -w "%{http_code}" \
  --max-time 10 \
  "${N8N_URL}" 2>/dev/null || echo "000")

echo "  HTTP status sin credenciales: ${response}"

# n8n con basic auth devuelve 401 cuando no hay credenciales
if [[ "$response" == "401" ]]; then
  echo "STATUS: PASS - n8n requiere autenticacion (HTTP 401)"
  exit 0
fi

# Algunos configs devuelven 200 con pagina de login pero sin acceso real a la API
# Verificar que la API de workflows requiere auth
api_response=$(curl -s -o /dev/null -w "%{http_code}" \
  --max-time 10 \
  "${N8N_URL}/api/v1/workflows" 2>/dev/null || echo "000")

echo "  HTTP status en /api/v1/workflows: ${api_response}"

if [[ "$api_response" == "401" || "$api_response" == "403" ]]; then
  echo "STATUS: PASS - n8n API requiere autenticacion (HTTP ${api_response})"
  exit 0
fi

echo "STATUS: FAIL (BLOQUEANTE) - n8n accesible sin autenticacion (UI: ${response}, API: ${api_response})"
exit 1
