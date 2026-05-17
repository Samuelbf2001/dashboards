#!/usr/bin/env bash
# SEC-05 [BLOQUEANTE] - Validacion de firma HMAC GHL
# Criterio: webhook con X-GHL-Signature invalida retorna 401
# Exit 0 = PASS, 1 = FAIL

set -euo pipefail

: "${N8N_HOST:?Requerida: N8N_HOST}"

ENDPOINT="https://${N8N_HOST}/ghl/contacts"
INVALID_SIGNATURE="sha256=invalidsignaturexxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

echo "=== SEC-05: HMAC validation ==="
echo "  Endpoint: ${ENDPOINT}"
echo "  Enviando firma HMAC invalida..."

response=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-GHL-Signature: ${INVALID_SIGNATURE}" \
  -d '{"type":"ContactCreate","locationId":"test_loc","id":"test_hmac_001"}' \
  --max-time 10 \
  "${ENDPOINT}" 2>/dev/null || echo "000")

echo "  HTTP status con firma invalida: ${response}"

if [[ "$response" == "401" || "$response" == "403" || "$response" == "400" ]]; then
  echo "STATUS: PASS - Firma HMAC invalida rechazada con HTTP ${response}"
  exit 0
fi

echo "STATUS: FAIL (BLOQUEANTE) - Firma HMAC invalida NO fue rechazada (recibio: ${response})"
exit 1
