#!/usr/bin/env bash
# ETL-09 [BLOQUEANTE] - Email sanitizado a lowercase
# Criterio: email "TEST@GMAIL.COM" se almacena como "test@gmail.com"
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

TEST_CONTACT_ID="test_email_etl09_$(date +%s)"
INPUT_EMAIL="TEST@GMAIL.COM"
EXPECTED_EMAIL="test@gmail.com"

PAYLOAD=$(cat <<EOF
{
  "type": "ContactCreate",
  "locationId": "${TEST_LOCATION_ID}",
  "id": "${TEST_CONTACT_ID}",
  "email": "${INPUT_EMAIL}",
  "firstName": "Email",
  "lastName": "Test09"
}
EOF
)

SIGNATURE=$(echo -n "${PAYLOAD}" | openssl dgst -sha256 -hmac "${WEBHOOK_SECRET}" | awk '{print "sha256="$2}')

echo "=== ETL-09: Email lowercase normalization ==="
echo "  Input email: ${INPUT_EMAIL}"
echo "  Expected: ${EXPECTED_EMAIL}"

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
email_stored=""
while [[ $(($(date +%s) - start_time)) -lt $MAX_WAIT ]]; do
  email_stored=$($PSQL -c "
    SELECT email FROM dim_contacts
    WHERE contact_id = '${TEST_CONTACT_ID}' AND is_current = TRUE LIMIT 1;
  " 2>/dev/null || echo "")
  if [[ -n "$email_stored" ]]; then
    break
  fi
  sleep 1
done

$PSQL -c "DELETE FROM dim_contacts WHERE contact_id = '${TEST_CONTACT_ID}';" 2>/dev/null || true

echo "  Email almacenado: ${email_stored}"

if [[ "$email_stored" == "$EXPECTED_EMAIL" ]]; then
  echo "STATUS: PASS - Email normalizado a lowercase correctamente"
  exit 0
fi

echo "STATUS: FAIL (BLOQUEANTE) - Email no normalizado: esperado='${EXPECTED_EMAIL}', almacenado='${email_stored}'"
exit 1
