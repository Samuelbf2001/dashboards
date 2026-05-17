#!/usr/bin/env bash
# ETL-03 [BLOQUEANTE] - Duplicados no se crean
# Criterio: mismo evento enviado 3 veces = 1 sola fila en BD (upsert idempotente)
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
TEST_CONTACT_ID="test_dedup_etl03_$(date +%s)"

PAYLOAD=$(cat <<EOF
{
  "type": "ContactCreate",
  "locationId": "${TEST_LOCATION_ID}",
  "id": "${TEST_CONTACT_ID}",
  "email": "dedup_test@test.com",
  "firstName": "Dedup",
  "lastName": "Test"
}
EOF
)

SIGNATURE=$(echo -n "${PAYLOAD}" | openssl dgst -sha256 -hmac "${WEBHOOK_SECRET}" | awk '{print "sha256="$2}')

echo "=== ETL-03: No duplicates ==="
echo "  Enviando el mismo contacto 3 veces: ${TEST_CONTACT_ID}"

# Enviar 3 veces
for i in 1 2 3; do
  code=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "X-GHL-Signature: ${SIGNATURE}" \
    -d "${PAYLOAD}" \
    --max-time 10 \
    "${ENDPOINT}" 2>/dev/null || echo "000")
  echo "  Envio #${i}: HTTP ${code}"
  sleep 2
done

echo "  Esperando procesamiento..."
sleep 5

export PGPASSWORD="$POSTGRES_PASSWORD"
PSQL="psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAq"

count=$($PSQL -c "SELECT COUNT(*) FROM dim_contacts WHERE contact_id = '${TEST_CONTACT_ID}';" 2>/dev/null || echo 0)
echo "  Filas en dim_contacts para este contact_id: ${count}"

# Limpiar
$PSQL -c "DELETE FROM dim_contacts WHERE contact_id = '${TEST_CONTACT_ID}';" 2>/dev/null || true

if [[ "$count" -eq 1 ]]; then
  echo "STATUS: PASS - Solo 1 fila creada tras 3 envios identicos"
  exit 0
fi

echo "STATUS: FAIL (BLOQUEANTE) - Se encontraron ${count} filas (esperado 1). Hay duplicados."
exit 1
