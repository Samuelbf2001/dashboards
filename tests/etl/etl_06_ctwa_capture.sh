#!/usr/bin/env bash
# ETL-06 [BLOQUEANTE] - ctwa_clid capturado desde Meta webhook
# Criterio: evento CTWA genera row en fact_ctwa_clicks con ctwa_clid no-null
# Exit 0 = PASS, 1 = FAIL

set -euo pipefail

: "${N8N_HOST:?Requerida: N8N_HOST}"
: "${POSTGRES_HOST:=localhost}"
: "${POSTGRES_PORT:=5432}"
: "${POSTGRES_DB:=ghl_analytics}"
: "${POSTGRES_USER:=sixteam_admin}"
: "${POSTGRES_PASSWORD:?Requerida: POSTGRES_PASSWORD}"

ENDPOINT="https://${N8N_HOST}/meta/ctwa"
TEST_CTWA_CLID="test_ctwa_clid_etl06_$(date +%s)"
TEST_PHONE="+573009876543"

# Payload simulado de Meta Cloud API CTWA referral
PAYLOAD=$(cat <<EOF
{
  "object": "whatsapp_business_account",
  "entry": [{
    "id": "wa_account_test",
    "changes": [{
      "value": {
        "messages": [{
          "from": "573009876543",
          "id": "wamid_test_001",
          "timestamp": "$(date +%s)",
          "type": "text",
          "text": { "body": "hola" },
          "referral": {
            "source_url": "https://fb.me/test_ad",
            "source_type": "ad",
            "source_id": "${TEST_CTWA_CLID}",
            "headline": "Anuncio de prueba ETL06",
            "body": "Descripcion de prueba",
            "media_type": "image",
            "image_url": "https://example.com/img.jpg",
            "ctwa_clid": "${TEST_CTWA_CLID}",
            "ads_id": "ad_test_001",
            "adset_id": "adset_test_001",
            "campaign_id": "campaign_test_001",
            "ad_name": "Anuncio ETL06",
            "campaign_name": "Campana ETL06"
          }
        }]
      },
      "field": "messages"
    }]
  }]
}
EOF
)

echo "=== ETL-06: CTWA capture ==="
echo "  ctwa_clid: ${TEST_CTWA_CLID}"

start_time=$(date +%s)
http_code=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d "${PAYLOAD}" \
  --max-time 10 \
  "${ENDPOINT}" 2>/dev/null || echo "000")

echo "  Webhook response: HTTP ${http_code}"

export PGPASSWORD="$POSTGRES_PASSWORD"
PSQL="psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAq"

MAX_WAIT=15
found=0
while [[ $(($(date +%s) - start_time)) -lt $MAX_WAIT ]]; do
  count=$($PSQL -c "SELECT COUNT(*) FROM fact_ctwa_clicks WHERE ctwa_clid = '${TEST_CTWA_CLID}';" 2>/dev/null || echo 0)
  if [[ "$count" -ge 1 ]]; then
    elapsed=$(($(date +%s) - start_time))
    echo "  Fila en fact_ctwa_clicks encontrada en ${elapsed}s"
    found=1
    break
  fi
  sleep 1
done

# Limpiar
$PSQL -c "DELETE FROM fact_ctwa_clicks WHERE ctwa_clid = '${TEST_CTWA_CLID}';" 2>/dev/null || true

if [[ $found -eq 1 ]]; then
  echo "STATUS: PASS"
  exit 0
fi

echo "STATUS: FAIL (BLOQUEANTE) - fact_ctwa_clicks sin fila tras ${MAX_WAIT}s"
exit 1
