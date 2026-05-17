#!/usr/bin/env bash
# ETL-10 [BLOQUEANTE] - Telefono normalizado a E.164
# Criterio: telefono "3001234567" (Colombia) se almacena "+573001234567"
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

TEST_CONTACT_ID="test_phone_etl10_$(date +%s)"
INPUT_PHONE="3001234567"
EXPECTED_PHONE="+573001234567"

PAYLOAD=$(cat <<EOF
{
  "type": "ContactCreate",
  "locationId": "${TEST_LOCATION_ID}",
  "id": "${TEST_CONTACT_ID}",
  "phone": "${INPUT_PHONE}",
  "email": "phone_test@test.com",
  "firstName": "Phone",
  "lastName": "Test10"
}
EOF
)

SIGNATURE=$(echo -n "${PAYLOAD}" | openssl dgst -sha256 -hmac "${WEBHOOK_SECRET}" | awk '{print "sha256="$2}')

echo "=== ETL-10: Phone E.164 normalization ==="
echo "  Input phone: ${INPUT_PHONE}"
echo "  Expected E.164: ${EXPECTED_PHONE}"

start_time=$(date +%s)
curl -s -o /dev/null \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-GHL-Signature: ${SIGNATURE}" \
  -d "${PAYLOAD}" \
  --max-time 10 \
  "https://${N8N_HOST}/ghl/contacts" 2>/dev/null

export PGPASSWORD="$POSTGRES_PASSWORD"
PSQL="psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAq"

MAX_WAIT=15
phone_stored=""
while [[ $(($(date +%s) - start_time)) -lt $MAX_WAIT ]]; do
  phone_stored=$($PSQL -c "
    SELECT phone FROM dim_contacts
    WHERE contact_id = '${TEST_CONTACT_ID}' AND is_current = TRUE LIMIT 1;
  " 2>/dev/null || echo "")
  if [[ -n "$phone_stored" ]]; then
    break
  fi
  sleep 1
done

$PSQL -c "DELETE FROM dim_contacts WHERE contact_id = '${TEST_CONTACT_ID}';" 2>/dev/null || true

echo "  Telefono almacenado: ${phone_stored}"

if [[ "$phone_stored" == "$EXPECTED_PHONE" ]]; then
  echo "STATUS: PASS - Telefono normalizado a E.164 correctamente"
  exit 0
fi

echo "STATUS: FAIL (BLOQUEANTE) - Telefono no normalizado: esperado='${EXPECTED_PHONE}', almacenado='${phone_stored}'"
exit 1
