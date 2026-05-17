#!/usr/bin/env bash
# SEC-07 [BLOQUEANTE] - Metabase sin acceso anonimo a BD raw
# Criterio: usuario sin login no puede hacer SQL queries (GET /api/dataset retorna 401)
# Exit 0 = PASS, 1 = FAIL

set -euo pipefail

: "${MB_SITE_URL:?Requerida: MB_SITE_URL (ej: https://analytics.tudominio.com)}"

ENDPOINT="${MB_SITE_URL}/api/dataset"

echo "=== SEC-07: Metabase no anonymous access ==="
echo "  Endpoint: ${ENDPOINT}"

response=$(curl -s -o /tmp/sec07_body.txt -w "%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"database":1,"query":{"source-table":1},"type":"query"}' \
  --max-time 10 \
  "${ENDPOINT}" 2>/dev/null || echo "000")

echo "  HTTP status sin autenticacion: ${response}"
body=$(cat /tmp/sec07_body.txt 2>/dev/null | head -3)
echo "  Response: ${body}"

if [[ "$response" == "401" || "$response" == "403" ]]; then
  echo "STATUS: PASS - Acceso anonimo a /api/dataset denegado con HTTP ${response}"
  exit 0
fi

echo "STATUS: FAIL (BLOQUEANTE) - /api/dataset accesible sin autenticacion (HTTP ${response})"
exit 1
