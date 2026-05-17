#!/usr/bin/env bash
# ETL-02 [BLOQUEANTE] - OpportunityUpdate escribe en fact_opp_stage_history
# Criterio: cambio de etapa genera row en fact_opp_stage_history
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

ENDPOINT="https://${N8N_HOST}/ghl/opportunities"
TEST_OPP_ID="test_opp_etl02_$(date +%s)"
TEST_CONTACT_ID="test_contact_etl02"

PAYLOAD=$(cat <<EOF
{
  "type": "OpportunityUpdate",
  "locationId": "${TEST_LOCATION_ID}",
  "id": "${TEST_OPP_ID}",
  "contactId": "${TEST_CONTACT_ID}",
  "pipelineId": "pipeline_test",
  "pipelineStageId": "stage_002",
  "previousStageId": "stage_001",
  "stageName": "Propuesta enviada",
  "previousStageName": "Nuevo lead",
  "status": "open",
  "monetaryValue": 1500000
}
EOF
)

SIGNATURE=$(echo -n "${PAYLOAD}" | openssl dgst -sha256 -hmac "${WEBHOOK_SECRET}" | awk '{print "sha256="$2}')

echo "=== ETL-02: OpportunityUpdate -> fact_opp_stage_history ==="
echo "  opportunity_id: ${TEST_OPP_ID}"

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

MAX_WAIT=15
found=0
while [[ $(($(date +%s) - start_time)) -lt $MAX_WAIT ]]; do
  count=$($PSQL -c "SELECT COUNT(*) FROM fact_opp_stage_history WHERE opportunity_id = '${TEST_OPP_ID}';" 2>/dev/null || echo 0)
  if [[ "$count" -ge 1 ]]; then
    elapsed=$(($(date +%s) - start_time))
    echo "  Fila en fact_opp_stage_history encontrada en ${elapsed}s"
    found=1
    break
  fi
  sleep 1
done

# Limpiar
$PSQL -c "DELETE FROM fact_opp_stage_history WHERE opportunity_id = '${TEST_OPP_ID}';" 2>/dev/null || true
$PSQL -c "DELETE FROM dim_opportunities WHERE opportunity_id = '${TEST_OPP_ID}';" 2>/dev/null || true

if [[ $found -eq 1 ]]; then
  echo "STATUS: PASS"
  exit 0
fi

echo "STATUS: FAIL (BLOQUEANTE) - fact_opp_stage_history sin fila tras ${MAX_WAIT}s"
exit 1
