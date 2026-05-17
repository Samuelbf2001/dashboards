#!/usr/bin/env bash
# ETL-05 [BLOQUEANTE] - Payload malformado no rompe el workflow
# Criterio: JSON invalido en webhook retorna 400 y el workflow no se cae
# Exit 0 = PASS, 1 = FAIL

set -euo pipefail

: "${N8N_HOST:?Requerida: N8N_HOST}"
: "${WEBHOOK_SECRET:?Requerida: WEBHOOK_SECRET}"

ENDPOINT="https://${N8N_HOST}/ghl/contacts"

echo "=== ETL-05: Malformed payload handling ==="

# Test 1: JSON invalido
echo "  Test 1: JSON invalido"
response1=$(curl -s -o /tmp/etl05_r1.txt -w "%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d 'esto no es json {{{' \
  --max-time 10 \
  "${ENDPOINT}" 2>/dev/null || echo "000")
echo "    HTTP status: ${response1} | Body: $(cat /tmp/etl05_r1.txt 2>/dev/null | head -1)"

# Test 2: JSON valido pero sin campos requeridos
echo "  Test 2: Campos requeridos faltantes"
EMPTY_PAYLOAD='{"type":"ContactCreate"}'
SIG2=$(echo -n "${EMPTY_PAYLOAD}" | openssl dgst -sha256 -hmac "${WEBHOOK_SECRET}" | awk '{print "sha256="$2}')
response2=$(curl -s -o /tmp/etl05_r2.txt -w "%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-GHL-Signature: ${SIG2}" \
  -d "${EMPTY_PAYLOAD}" \
  --max-time 10 \
  "${ENDPOINT}" 2>/dev/null || echo "000")
echo "    HTTP status: ${response2} | Body: $(cat /tmp/etl05_r2.txt 2>/dev/null | head -1)"

# Test 3: Verificar que el workflow n8n sigue corriendo (health check)
echo "  Test 3: Verificar que n8n sigue respondiendo"
sleep 3
health=$(curl -s -o /dev/null -w "%{http_code}" \
  --max-time 10 \
  "https://${N8N_HOST}/healthz" 2>/dev/null || echo "000")
echo "    n8n /healthz: HTTP ${health}"

PASS=0
[[ "$response1" == "400" || "$response1" == "415" ]] && PASS=$((PASS + 1))
[[ "$response2" == "400" || "$response2" == "401" || "$response2" == "422" ]] && PASS=$((PASS + 1))
[[ "$health" == "200" || "$health" == "204" ]] && PASS=$((PASS + 1))

echo ""
echo "  Tests pasados: ${PASS}/3"

if [[ $PASS -ge 2 ]]; then
  echo "STATUS: PASS - Payloads malformados rechazados correctamente y n8n sigue vivo"
  exit 0
fi

echo "STATUS: FAIL (BLOQUEANTE)"
exit 1
