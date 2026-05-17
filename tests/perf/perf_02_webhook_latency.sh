#!/usr/bin/env bash
# PERF-02 [BLOQUEANTE] - Latencia webhook -> PostgreSQL en P99 < 10 segundos
# Criterio: medir latencia end-to-end de 100 requests, validar P99 < 10s
# Exit 0 = PASS, 1 = FAIL

set -euo pipefail

: "${N8N_HOST:?Requerida: N8N_HOST}"
: "${WEBHOOK_SECRET:?Requerida: WEBHOOK_SECRET}"
: "${POSTGRES_HOST:=localhost}"
: "${POSTGRES_PORT:=5432}"
: "${POSTGRES_DB:=ghl_analytics}"
: "${POSTGRES_USER:=sixteam_admin}"
: "${POSTGRES_PASSWORD:?Requerida: POSTGRES_PASSWORD}"
: "${TEST_LOCATION_ID:=loc_test_perf}"
: "${SAMPLE_SIZE:=20}"
: "${P99_LIMIT:=10}"

echo "=== PERF-02: Webhook latency P99 ==="
echo "  Sample size: ${SAMPLE_SIZE} requests"
echo "  P99 limite: ${P99_LIMIT}s"

export PGPASSWORD="$POSTGRES_PASSWORD"
PSQL="psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -tAq"
ENDPOINT="https://${N8N_HOST}/ghl/contacts"

LATENCIES=()

for i in $(seq 1 $SAMPLE_SIZE); do
  CONTACT_ID="perf_test_$(date +%s%3N)_${i}"
  PAYLOAD=$(printf '{"type":"ContactCreate","locationId":"%s","id":"%s","email":"perf%d@test.com","firstName":"Perf","lastName":"Test"}' \
    "$TEST_LOCATION_ID" "$CONTACT_ID" "$i")
  SIGNATURE=$(echo -n "${PAYLOAD}" | openssl dgst -sha256 -hmac "${WEBHOOK_SECRET}" | awk '{print "sha256="$2}')

  send_time=$(date +%s%3N)

  curl -s -o /dev/null \
    -X POST \
    -H "Content-Type: application/json" \
    -H "X-GHL-Signature: ${SIGNATURE}" \
    -d "${PAYLOAD}" \
    --max-time 15 \
    "${ENDPOINT}" 2>/dev/null

  # Polling hasta que aparezca en BD
  found=0
  for _ in $(seq 1 15); do
    count=$($PSQL -c "SELECT COUNT(*) FROM dim_contacts WHERE contact_id = '${CONTACT_ID}';" 2>/dev/null || echo 0)
    if [[ "$count" -ge 1 ]]; then
      found=1
      break
    fi
    sleep 1
  done

  arrive_time=$(date +%s%3N)
  latency_ms=$((arrive_time - send_time))

  if [[ $found -eq 1 ]]; then
    LATENCIES+=($latency_ms)
    printf "  Request %3d: %dms\n" "$i" "$latency_ms"
  else
    LATENCIES+=(15000)
    printf "  Request %3d: TIMEOUT (>15s)\n" "$i"
  fi

  # Limpiar
  $PSQL -c "DELETE FROM dim_contacts WHERE contact_id = '${CONTACT_ID}';" 2>/dev/null || true
done

# Calcular P99
sorted=($(printf '%s\n' "${LATENCIES[@]}" | sort -n))
total=${#sorted[@]}
p99_idx=$(echo "scale=0; ($total * 99 / 100 - 1)" | bc)
[[ $p99_idx -lt 0 ]] && p99_idx=0
P99_MS=${sorted[$p99_idx]}
P99_S=$(echo "scale=2; $P99_MS / 1000" | bc)

# Promedio
sum=0
for v in "${LATENCIES[@]}"; do sum=$((sum + v)); done
avg_ms=$((sum / total))
avg_s=$(echo "scale=2; $avg_ms / 1000" | bc)

echo ""
echo "  Promedio: ${avg_ms}ms (${avg_s}s)"
echo "  P99: ${P99_MS}ms (${P99_S}s)"
echo "  Limite P99: ${P99_LIMIT}s"

if (( P99_MS <= (P99_LIMIT * 1000) )); then
  echo "STATUS: PASS - P99 latencia: ${P99_S}s"
  exit 0
fi

echo "STATUS: FAIL (BLOQUEANTE) - P99 latencia ${P99_S}s supera limite de ${P99_LIMIT}s"
exit 1
