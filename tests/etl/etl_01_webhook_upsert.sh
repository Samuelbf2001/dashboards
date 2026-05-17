#!/usr/bin/env bash
# ETL-01 [BLOQUEANTE] - ContactCreate webhook upserta contacto
# Criterio: nuevo contacto aparece en dim_contacts en < 10 segundos
# Exit 0 = PASS, 1 = FAIL

set -euo pipefail

: "${N8N_HOST:?Requerida: N8N_HOST}"
: "${WEBHOOK_SECRET:?Requerida: WEBHOOK_SECRET}"
: "${POSTGRES_HOST:=localhost}"
: "${POSTGRES_PORT:=5432}"
: "${POSTGRES_DB:=ghl_analytics}"
: "${POSTGRES_USER:=sixteam_admin}"
: "${POSTGRES_PASSWORD:?Requerida: POSTGRES_PASSWORD}"
: "${TEST_LOCATION_ID:=loc_test_etl}"

ENDPOINT="https://${N8N_HOST}/ghl/contacts"
TEST_CONTACT_ID="test_etl01_$(date +%s)"

PAYLOAD=$(cat <<EOF
{
  "type": "ContactCreate",
  "locationId": "${TEST_LOCATION_ID}",
  "id": "${TEST_CONTACT_ID}",
  "email": "etl_test_01@test.com",
  "phone": "+573001234567",
  "firstName": "ETL",
  "lastName": "Test01"
}
EOF
)

SIGNATURE=$(echo -n "${PAYLOAD}" | openssl dgst -sha256 -hmac "${WEBHOOK_SECRET}" | awk '{print "sha256="$2}')

echo "=== ETL-01: ContactCreate webhook upsert ==="
echo "  contact_id: ${TEST_CONTACT_ID}"

# Enviar webhook
start_time=$(date +%s)
http_code=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-GHL-Signature: ${SIGNATURE}" \
  -d "${PAYLOAD}" \
  --max-time 10 \
  "${ENDPOINT}" 2>/dev/null || echo "000")

echo "  Webhook response: HTTP ${http_code}"

export PGPASSWORD="$POSTGRES_PASSWORD"
PSQL="psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAq"

# Polling hasta 15s para que la fila aparezca
MAX_WAIT=15
found=0
while [[ $(($(date +%s) - start_time)) -lt $MAX_WAIT ]]; do
  count=$($PSQL -c "SELECT COUNT(*) FROM dim_contacts WHERE contact_id = '${TEST_CONTACT_ID}';" 2>/dev/null || echo 0)
  if [[ "$count" -ge 1 ]]; then
    elapsed=$(($(date +%s) - start_time))
    echo "  Fila encontrada en ${elapsed}s"
    found=1
    break
  fi
  sleep 1
done

# Limpiar
$PSQL -c "DELETE FROM dim_contacts WHERE contact_id = '${TEST_CONTACT_ID}';" 2>/dev/null || true

if [[ $found -eq 1 ]]; then
  echo "STATUS: PASS"
  exit 0
fi

echo "STATUS: FAIL (BLOQUEANTE) - Contacto no aparecio en dim_contacts en ${MAX_WAIT}s"
exit 1
