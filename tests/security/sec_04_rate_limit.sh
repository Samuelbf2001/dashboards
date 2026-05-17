#!/usr/bin/env bash
# SEC-04 [BLOQUEANTE] - Rate limit activo en webhooks
# Criterio: enviar 600 req/10s a /ghl/contacts, validar que alguna recibe 429
# Exit 0 = PASS, 1 = FAIL

set -euo pipefail

: "${N8N_HOST:?Requerida: N8N_HOST}"
: "${WEBHOOK_SECRET:?Requerida: WEBHOOK_SECRET}"

ENDPOINT="https://${N8N_HOST}/ghl/contacts"
TOTAL_REQUESTS=200
CONCURRENT=50
GOT_429=0

echo "=== SEC-04: Rate limit ==="
echo "  Endpoint: ${ENDPOINT}"
echo "  Enviando ${TOTAL_REQUESTS} requests concurrentes..."

# Funcion para enviar un request y registrar el status
send_request() {
  code=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "X-GHL-Signature: test_rate_limit" \
    -d '{"type":"ContactCreate","locationId":"test","id":"test123"}' \
    --max-time 5 \
    "${ENDPOINT}" 2>/dev/null || echo "000")
  echo "$code"
}

export -f send_request
export ENDPOINT

# Enviar requests en paralelo y capturar status codes
codes=$(seq 1 $TOTAL_REQUESTS | xargs -P $CONCURRENT -I{} bash -c 'send_request' 2>/dev/null)

GOT_429=$(echo "$codes" | grep -c "429" || true)
GOT_200=$(echo "$codes" | grep -c "200" || true)

echo "  Responses 200: ${GOT_200}"
echo "  Responses 429: ${GOT_429}"

if [[ "$GOT_429" -gt 0 ]]; then
  echo "STATUS: PASS - Rate limit activo (${GOT_429} requests bloqueadas con 429)"
  exit 0
fi

echo "STATUS: FAIL (BLOQUEANTE) - Ningun request recibio 429. Rate limit no esta activo."
exit 1
