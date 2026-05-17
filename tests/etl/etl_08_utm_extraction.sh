#!/usr/bin/env bash
# ETL-08 [BLOQUEANTE] - UTMs de formularios GHL extraidos
# Criterio: attributionSource.utmSource aparece en dim_contacts.utm_source_first
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

TEST_CONTACT_ID="test_utm_etl08_$(date +%s)"
TEST_UTM_SOURCE="facebook_paid_test"

PAYLOAD=$(cat <<EOF
{
  "type": "ContactCreate",
  "locationId": "${TEST_LOCATION_ID}",
  "id": "${TEST_CONTACT_ID}",
  "email": "utm_test@test.com",
  "firstName": "UTM",
  "lastName": "Test08",
  "attributionSource": {
    "utmSource": "${TEST_UTM_SOURCE}",
    "utmMedium": "cpc",
    "utmCampaign": "campana_test_etl08",
    "utmContent": "anuncio_a",
    "utmTerm": "keyword_test",
    "url": "https://landing.test.com?utm_source=${TEST_UTM_SOURCE}"
  }
}
EOF
)

SIGNATURE=$(echo -n "${PAYLOAD}" | openssl dgst -sha256 -hmac "${WEBHOOK_SECRET}" | awk '{print "sha256="$2}')

echo "=== ETL-08: UTM extraction ==="
echo "  contact_id: ${TEST_CONTACT_ID}"
echo "  utmSource esperado: ${TEST_UTM_SOURCE}"

start_time=$(date +%s)
http_code=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-GHL-Signature: ${SIGNATURE}" \
  -d "${PAYLOAD}" \
  --max-time 10 \
  "https://${N8N_HOST}/ghl/contacts" 2>/dev/null || echo "000")

echo "  Webhook response: HTTP ${http_code}"

export PGPASSWORD="$POSTGRES_PASSWORD"
PSQL="psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAq"

MAX_WAIT=15
found=0
while [[ $(($(date +%s) - start_time)) -lt $MAX_WAIT ]]; do
  utm_stored=$($PSQL -c "
    SELECT utm_source_first FROM dim_contacts
    WHERE contact_id = '${TEST_CONTACT_ID}' AND is_current = TRUE
    LIMIT 1;
  " 2>/dev/null || echo "")

  if [[ -n "$utm_stored" && "$utm_stored" != "" ]]; then
    elapsed=$(($(date +%s) - start_time))
    echo "  utm_source_first encontrado en ${elapsed}s: ${utm_stored}"
    found=1
    break
  fi
  sleep 1
done

$PSQL -c "DELETE FROM dim_contacts WHERE contact_id = '${TEST_CONTACT_ID}';" 2>/dev/null || true

if [[ $found -eq 1 ]]; then
  if [[ "$utm_stored" == "$TEST_UTM_SOURCE" ]]; then
    echo "STATUS: PASS - UTM extraido correctamente"
    exit 0
  else
    echo "STATUS: FAIL - UTM guardado incorrectamente: esperado='${TEST_UTM_SOURCE}', guardado='${utm_stored}'"
    exit 1
  fi
fi

echo "STATUS: FAIL (BLOQUEANTE) - utm_source_first no fue extraido en ${MAX_WAIT}s"
exit 1
