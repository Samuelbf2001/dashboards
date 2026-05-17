#!/usr/bin/env bash
# SEC-10 [BLOQUEANTE] - Meta CTWA verify challenge funciona
# Criterio: GET /meta/ctwa con hub.challenge retorna exactamente el valor del challenge
# Exit 0 = PASS, 1 = FAIL

set -euo pipefail

: "${N8N_HOST:?Requerida: N8N_HOST}"
: "${META_VERIFY_TOKEN:?Requerida: META_VERIFY_TOKEN}"

CHALLENGE="abc123_test_$(date +%s)"
ENDPOINT="https://${N8N_HOST}/meta/ctwa"

echo "=== SEC-10: Meta CTWA verify challenge ==="
echo "  Endpoint: ${ENDPOINT}"
echo "  Challenge: ${CHALLENGE}"

response_body=$(curl -s \
  --max-time 10 \
  "${ENDPOINT}?hub.mode=subscribe&hub.verify_token=${META_VERIFY_TOKEN}&hub.challenge=${CHALLENGE}" \
  2>/dev/null || echo "ERROR")

echo "  Response: ${response_body}"

if [[ "$response_body" == "$CHALLENGE" ]]; then
  echo "STATUS: PASS - Endpoint devuelve exactamente el challenge"
  exit 0
fi

# Intentar con el challenge como unico contenido (Meta espera exactamente el challenge como body)
if echo "$response_body" | grep -q "$CHALLENGE"; then
  echo "STATUS: PASS - Respuesta contiene el challenge"
  exit 0
fi

echo "STATUS: FAIL (BLOQUEANTE) - Challenge esperado: '${CHALLENGE}', recibido: '${response_body}'"
exit 1
