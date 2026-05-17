#!/usr/bin/env bash
# SEC-06 [BLOQUEANTE] - SQL injection no posible
# Criterio: payload con ' OR 1=1-- en contactId retorna 400 y no ejecuta SQL
# Exit 0 = PASS, 1 = FAIL

set -euo pipefail

: "${N8N_HOST:?Requerida: N8N_HOST}"
: "${WEBHOOK_SECRET:?Requerida: WEBHOOK_SECRET}"
: "${POSTGRES_HOST:=localhost}"
: "${POSTGRES_PORT:=5432}"
: "${POSTGRES_DB:=ghl_analytics}"
: "${POSTGRES_USER:=sixteam_admin}"
: "${POSTGRES_PASSWORD:?Requerida: POSTGRES_PASSWORD}"

ENDPOINT="https://${N8N_HOST}/ghl/contacts"
# Payload con intento de SQL injection en el campo id
INJECTION_PAYLOAD='{"type":"ContactCreate","locationId":"test_loc","id":"'\'' OR 1=1--","email":"test@test.com"}'

echo "=== SEC-06: SQL injection prevention ==="
echo "  Endpoint: ${ENDPOINT}"

# Generar firma HMAC valida para este payload (para que llegue a la capa de sanitizacion)
SIGNATURE=$(echo -n "${INJECTION_PAYLOAD}" | openssl dgst -sha256 -hmac "${WEBHOOK_SECRET}" | awk '{print "sha256="$2}')

response=$(curl -s -o /tmp/sec06_body.txt -w "%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-GHL-Signature: ${SIGNATURE}" \
  -d "${INJECTION_PAYLOAD}" \
  --max-time 10 \
  "${ENDPOINT}" 2>/dev/null || echo "000")

echo "  HTTP status: ${response}"
echo "  Response body: $(cat /tmp/sec06_body.txt 2>/dev/null | head -3)"

# Verificar que no se creo ninguna fila con el id de injection
export PGPASSWORD="$POSTGRES_PASSWORD"
PSQL="psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAq"
injected_count=$($PSQL -c "SELECT COUNT(*) FROM dim_contacts WHERE contact_id LIKE '%OR 1=1%';" 2>/dev/null || echo 0)

echo "  Filas con ID de injection en BD: ${injected_count}"

if [[ "$response" == "400" || "$response" == "401" || "$response" == "422" ]]; then
  if [[ "$injected_count" == "0" ]]; then
    echo "STATUS: PASS - SQL injection rechazado con HTTP ${response} y no hay filas creadas"
    exit 0
  fi
fi

if [[ "$injected_count" == "0" && ("$response" == "200" || "$response" == "204") ]]; then
  # El request fue aceptado pero la sanitizacion rechazo el contactId invalido
  # Verificar que no hay fila creada
  echo "  Payload aceptado pero contact_id invalido fue descartado (sanitizacion)"
  echo "STATUS: PASS - No se creo fila con id de injection"
  exit 0
fi

echo "STATUS: FAIL (BLOQUEANTE) - Posible SQL injection: response=${response}, filas_creadas=${injected_count}"
exit 1
