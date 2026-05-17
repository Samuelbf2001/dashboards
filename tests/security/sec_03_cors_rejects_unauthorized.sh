#!/usr/bin/env bash
# SEC-03 [BLOQUEANTE] - CORS rechaza origenes no autorizados
# Criterio: curl con Origin: https://malicioso.com a /ghl/contacts recibe 403
#   o no recibe header Access-Control-Allow-Origin
# Exit 0 = PASS, 1 = FAIL

set -euo pipefail

: "${N8N_HOST:?Requerida: N8N_HOST (ej: n8n.tudominio.com)}"

UNAUTHORIZED_ORIGIN="https://malicioso.com"
ENDPOINT="https://${N8N_HOST}/ghl/contacts"

echo "=== SEC-03: CORS rejects unauthorized origins ==="
echo "  Endpoint: ${ENDPOINT}"
echo "  Origin: ${UNAUTHORIZED_ORIGIN}"

response=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Origin: ${UNAUTHORIZED_ORIGIN}" \
  -H "Content-Type: application/json" \
  --max-time 10 \
  -X OPTIONS \
  "${ENDPOINT}" 2>/dev/null || echo "000")

headers=$(curl -s -D - -o /dev/null \
  -H "Origin: ${UNAUTHORIZED_ORIGIN}" \
  --max-time 10 \
  -X OPTIONS \
  "${ENDPOINT}" 2>/dev/null || echo "")

echo "  HTTP status: ${response}"

# Verificar que no devuelve el origen no autorizado en ACAO header
if echo "$headers" | grep -qi "access-control-allow-origin: ${UNAUTHORIZED_ORIGIN}"; then
  echo "STATUS: FAIL (BLOQUEANTE) - CORS permite origen no autorizado"
  echo "  Header encontrado: $(echo "$headers" | grep -i access-control-allow-origin)"
  exit 1
fi

if [[ "$response" == "403" || "$response" == "401" || "$response" == "405" ]]; then
  echo "  CORS bloqueo con HTTP ${response}"
  echo "STATUS: PASS"
  exit 0
fi

# Si no hay header ACAO, tambien es correcto (no CORS habilitado para ese origen)
if ! echo "$headers" | grep -qi "access-control-allow-origin"; then
  echo "  No se encontro Access-Control-Allow-Origin header - origen rechazado"
  echo "STATUS: PASS"
  exit 0
fi

echo "STATUS: FAIL (BLOQUEANTE) - CORS no bloquea el origen malicioso"
exit 1
